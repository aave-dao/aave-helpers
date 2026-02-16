import { defineConfig } from 'tsdown';

export default defineConfig({
  entry: ['./index.ts', './cli.ts'],
  format: ['esm', 'cjs'],
  dts: { entry: ['./index.ts'] },
  clean: true,
});
