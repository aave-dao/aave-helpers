import { describe, it, expect } from 'vitest';
import { readFileSync, existsSync } from 'fs';
import { join, resolve } from 'path';
import { diffReports } from '../diff/protocol-diff';
import { AaveV3Snapshot } from '../diff/snapshot-types';

describe('Protocol Diff', () => {
  const loadSnapshot = (filename: string): AaveV3Snapshot => {
    // Try multiple path resolutions to find the reports directory
    const possiblePaths = [
      join(process.cwd(), 'reports', filename),
      join(process.cwd(), '../../reports', filename),
      join(__dirname, '../../../reports', filename),
      resolve(__dirname, '../../../reports', filename),
    ];

    for (const path of possiblePaths) {
      if (existsSync(path)) {
        return JSON.parse(readFileSync(path, 'utf-8'));
      }
    }

    throw new Error(
      `Could not find report file: ${filename}. Tried paths: ${possiblePaths.join(', ')}`
    );
  };

  describe('diffReports', () => {
    it('should generate diff between default_before and default_after', async () => {
      const before = loadSnapshot('default_before.json');
      const after = loadSnapshot('default_after.json');

      const result = await diffReports(before, after);

      // Snapshot test - will create a snapshot file on first run
      expect(result).toMatchSnapshot();
    });

    it('should handle reserves added correctly', async () => {
      const before = loadSnapshot('default_before.json');
      const after = loadSnapshot('default_after.json');

      const result = await diffReports(before, after);

      // Check that new reserves are detected and rendered
      expect(result).toContain('Reserve changes');

      // Should contain reserve information
      if (Object.keys(after.reserves).length > Object.keys(before.reserves).length) {
        expect(result).toContain('added');
      }
    });

    it('should handle reserves altered correctly', async () => {
      const before = loadSnapshot('default_before.json');
      const after = loadSnapshot('default_after.json');

      const result = await diffReports(before, after);

      // Check for altered reserves rendering
      const hasAlteredReserves = Object.keys(before.reserves).some((key) => {
        return (
          after.reserves[key] &&
          JSON.stringify(before.reserves[key]) !== JSON.stringify(after.reserves[key])
        );
      });

      if (hasAlteredReserves) {
        expect(result).toContain('altered');
      }
    });

    it('should handle eMode changes correctly', async () => {
      const before = loadSnapshot('default_before.json');
      const after = loadSnapshot('default_after.json');

      const result = await diffReports(before, after);

      const hasEmodeChanges = JSON.stringify(before.eModes) !== JSON.stringify(after.eModes);

      if (hasEmodeChanges) {
        expect(result).toContain('Emodes changed');
      }
    });

    it('should include raw diff at the end', async () => {
      const before = loadSnapshot('default_before.json');
      const after = loadSnapshot('default_after.json');

      const result = await diffReports(before, after);

      // Should always include raw diff section
      expect(result).toContain('## Raw diff');
      expect(result).toContain('```json');
    });

    it('should handle identical snapshots', async () => {
      const before = loadSnapshot('default_before.json');
      const after = JSON.parse(JSON.stringify(before)); // Deep clone

      const result = await diffReports(before, after);

      // Should still generate a report but with minimal changes
      expect(result).toContain('## Raw diff');
      expect(typeof result).toBe('string');
    });
  });
});
