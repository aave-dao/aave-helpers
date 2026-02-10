#!/usr/bin/env node
import { t as diffSnapshots } from "./protocol-diff-CW6T4gs9.mjs";
import { mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname } from "path";
import { Command } from "commander";

//#region cli.ts
const program = new Command();
program.name("foundry-seatbelt").description("Aave protocol snapshot tooling").version("1.0.0");
program.command("diff-snapshots").description("Diff two Aave V3 protocol snapshot JSON files and produce a markdown report").argument("<before>", "path to the before snapshot JSON").argument("<after>", "path to the after snapshot JSON").requiredOption("-o, --out <path>", "output path for the markdown report").action((beforePath, afterPath, opts) => {
	const md = diffSnapshots(JSON.parse(readFileSync(beforePath, "utf-8")), JSON.parse(readFileSync(afterPath, "utf-8")));
	mkdirSync(dirname(opts.out), { recursive: true });
	writeFileSync(opts.out, md, "utf-8");
});
program.parse();

//#endregion
export {  };