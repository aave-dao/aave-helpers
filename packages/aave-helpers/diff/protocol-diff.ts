import { writeFileSync } from 'fs';
import { diff } from './diff';
import { renderEmodeDiff } from './emode';
import { renderReserve, renderReserveDiff } from './reserve';
import { type AaveV3Snapshot } from './snapshot-types';
import { renderStrategy, renderStrategyDiff } from './strategy';
import { diffRawStorage } from './raw-storage-diff';
import {
  BlockscoutStyleSourceCode,
  getSourceCode,
  parseBlockscoutStyleSourceCode,
  parseEtherscanStyleSourceCode,
  StandardJsonInput,
  diffCode,
} from '@bgd-labs/toolbox';

function hasDiff(input: Record<string, any>): boolean {
  if (!input) return false;
  return !!Object.keys(input).find(
    (key) =>
      typeof input[key as keyof typeof input] === 'object' &&
      input[key as keyof typeof input] !== null &&
      (input[key as keyof typeof input].hasOwnProperty('from') ||
        input[key as keyof typeof input].hasOwnProperty('to'))
  );
}

export async function diffReports<A extends AaveV3Snapshot, B extends AaveV3Snapshot>(
  pre: A,
  post: B
) {
  const chainId = pre.chainId;
  // if raw is present, it already is a diff, so no need to diff it
  let raw;
  if (post.raw) {
    raw = { ...post.raw };
    delete post.raw;
  }
  let logs;
  if (post.logs) {
    logs = { ...post.logs };
    delete post.logs;
  }
  const diffResult = diff(pre, post);
  const diffResultWithoutUnchanged = diff(pre, post, true);
  if (raw) {
    diffResultWithoutUnchanged.raw = raw as any;
  }
  if (logs) {
    diffResultWithoutUnchanged.logs = logs as any;
  }

  // create report
  let content = '';
  if (diffResult.reserves) {
    const reservesAdded = Object.keys(diffResult.reserves)
      .map((reserveKey) => {
        // to being present on reserve level % trueish means reserve was added
        if ((diffResult.reserves[reserveKey] as any).to) {
          let report = renderReserve((diffResult.reserves[reserveKey] as any).to, chainId);
          report += renderStrategy(post.strategies[reserveKey]);
          return report;
        }
      })
      .filter((i) => i);
    const reservesRemoved = Object.keys(diffResult.reserves)
      .map((reserveKey) => {
        // from being present on reserve level % trueish means reserve was removed
        if ((diffResult.reserves[reserveKey] as any).from) {
          return renderReserve((diffResult.reserves[reserveKey] as any).from, chainId);
        }
      })
      .filter((i) => i);
    const reservesAltered = Object.keys(diffResult.reserves)
      .map((reserveKey) => {
        // Check if this is not an added/removed reserve (no 'from' property at reserve level)
        const reserveDiff = diffResult.reserves[reserveKey] as any;
        if (!(typeof reserveDiff === 'object' && reserveDiff !== null && 'from' in reserveDiff)) {
          const hasChangedReserveProperties = hasDiff(diffResult.reserves[reserveKey]);
          const preIr = getStrategyImageUrl(pre.strategies[reserveKey]);
          const postIr = getStrategyImageUrl(post.strategies[reserveKey]);
          const hasChangedIr = preIr !== postIr;
          if (!hasChangedReserveProperties && !hasChangedIr) return;
          // diff reserve
          let report = renderReserveDiff(diffResult.reserves[reserveKey] as any, chainId);
          // diff irs
          if (hasChangedIr) {
            report += renderStrategyDiff(
              diff(pre.strategies[reserveKey], post.strategies[reserveKey]) as any
            );
            report += `| interestRate | ![before](${preIr}) | ![after](${postIr}) |`;
          }

          return report;
        }
      })
      .filter((i) => i);
    if (reservesAdded.length || reservesRemoved.length || reservesAltered.length) {
      content += '## Reserve changes\n\n';
      if (reservesAdded.length) {
        content += `### ${reservesAdded.length > 1 ? 'Reserve' : 'Reserves'} added\n\n`;
        content += reservesAdded.join('\n\n');
        content += '\n\n';
      }

      if (reservesAltered.length) {
        content += `### ${reservesAltered.length > 1 ? 'Reserve' : 'Reserves'} altered\n\n`;
        content += reservesAltered.join('\n\n');
        content += '\n\n';
      }

      if (reservesRemoved.length) {
        content += `### ${reservesRemoved.length > 1 ? 'Reserve' : 'Reserves'} removed\n\n`;
        content += reservesRemoved.join('\n\n');
        content += '\n\n';
      }
    }
  }

  if (diffResultWithoutUnchanged.eModes) {
    content += '## Emodes changed\n\n';
    for (const eMode of Object.keys(diffResult.eModes)) {
      const hasChanges = hasDiff(diffResult.eModes?.[eMode]);
      content += `### EMode: ${post.eModes[eMode].label}(id: ${post.eModes[eMode].eModeCategory})\n\n`;
      if (hasChanges) {
        content += renderEmodeDiff(
          diff(pre.eModes[eMode] || {}, post.eModes[eMode] || {}) as any,
          pre,
          post
        );
      } else if (!pre.eModes[eMode] || !post.eModes[eMode]) {
        content += renderEmodeDiff(
          diff(pre.eModes[eMode] || {}, post.eModes[eMode] || {}) as any,
          pre,
          post
        );
      }
      content += '\n\n';
    }
  }

  if (raw) {
    diffRawStorage(pre.chainId, raw);
  }

  try {
    if (diffResultWithoutUnchanged.poolConfig) {
      for (const key of Object.keys(diffResult.poolConfig)) {
        try {
          if (
            typeof (diffResult as any).poolConfig[key] === 'object' &&
            (diffResult as any).poolConfig[key].hasOwnProperty('from')
          ) {
            const fromAddress = (diffResult as any).poolConfig[key].from;
            const toAddress = (diffResult as any).poolConfig[key].to;
            const sources = await Promise.all([
              getSourceCode({
                chainId: Number(pre.chainId),
                address: fromAddress,
                apiKey: process.env.ETHERSCAN_API_KEY,
                apiUrl: process.env.EXPLORER_PROXY,
              }),
              getSourceCode({
                chainId: Number(pre.chainId),
                address: toAddress,
                apiKey: process.env.ETHERSCAN_API_KEY,
                apiUrl: process.env.EXPLORER_PROXY,
              }),
            ]);
            const source1: StandardJsonInput = (sources[0] as BlockscoutStyleSourceCode)
              .AdditionalSources
              ? parseBlockscoutStyleSourceCode(sources[0] as BlockscoutStyleSourceCode)
              : parseEtherscanStyleSourceCode(sources[0].SourceCode);
            const source2: StandardJsonInput = (sources[0] as BlockscoutStyleSourceCode)
              .AdditionalSources
              ? parseBlockscoutStyleSourceCode(sources[1] as BlockscoutStyleSourceCode)
              : parseEtherscanStyleSourceCode(sources[1].SourceCode);
            const diff = await diffCode(source1, source2);
            const flat = Object.keys(diff).reduce((acc, key) => {
              acc += diff[key];
              return acc;
            }, '');
            writeFileSync(`./diffs/${pre.chainId}_${key}_${fromAddress}_${toAddress}.diff`, flat);
          }
        } catch (e) {
          console.info('error diffing the code');
          console.info(
            'this can happen if etherscan is not available, the code is not verified or not deployed yet'
          );
        }
      }
    }
  } catch (e) {}

  content += `## Raw diff\n\n\`\`\`json\n${JSON.stringify(diffResultWithoutUnchanged, null, 2)}\n\`\`\``;
  return content;
}
