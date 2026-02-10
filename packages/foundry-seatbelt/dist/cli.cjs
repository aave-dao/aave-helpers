#!/usr/bin/env node
const require_protocol_diff = require('./protocol-diff-hxe6EmbG.cjs');
let fs = require("fs");
let path = require("path");
let commander = require("commander");

//#region cli.ts
const program = new commander.Command();
program.name("foundry-seatbelt").description("Aave protocol snapshot tooling").version("1.0.0");
program.command("diff-snapshots").description("Diff two Aave V3 protocol snapshot JSON files and produce a markdown report").argument("<before>", "path to the before snapshot JSON").argument("<after>", "path to the after snapshot JSON").requiredOption("-o, --out <path>", "output path for the markdown report").action((beforePath, afterPath, opts) => {
	const md = require_protocol_diff.diffSnapshots(JSON.parse((0, fs.readFileSync)(beforePath, "utf-8")), JSON.parse((0, fs.readFileSync)(afterPath, "utf-8")));
	(0, fs.mkdirSync)((0, path.dirname)(opts.out), { recursive: true });
	(0, fs.writeFileSync)(opts.out, md, "utf-8");
});
program.parse();

//#endregion