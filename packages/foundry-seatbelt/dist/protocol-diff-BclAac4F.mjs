import { bitmapToIndexes, getClient, parseLogs } from "@bgd-labs/toolbox";
import { formatUnits, getAddress } from "viem";
import * as addresses from "@bgd-labs/aave-address-book";
import { findObjectPaths } from "find-object-paths";

//#region diff.ts
function diff(a, b, removeUnchanged) {
	const out = {};
	for (const key in a) if (!Object.prototype.hasOwnProperty.call(b, key)) out[key] = {
		from: a[key],
		to: null
	};
	else if (typeof a[key] === "object" && a[key] !== null && typeof b[key] === "object" && b[key] !== null) {
		const nested = diff(a[key], b[key], removeUnchanged);
		if (Object.keys(nested).length > 0) out[key] = nested;
	} else if (a[key] === b[key]) {
		if (!removeUnchanged) out[key] = a[key];
	} else out[key] = {
		from: a[key],
		to: b[key]
	};
	for (const key in b) if (!Object.prototype.hasOwnProperty.call(a, key)) out[key] = {
		from: null,
		to: b[key]
	};
	return out;
}
/**
* Check if a diff entry represents a changed value (has `from`/`to` shape).
*/
function isChange(value) {
	return typeof value === "object" && value !== null && "from" in value && "to" in value;
}
/**
* Check if any direct child of the diff object has changes.
*/
function hasChanges(diffObj) {
	if (!diffObj) return false;
	return Object.values(diffObj).some(isChange);
}

//#endregion
//#region utils/markdown.ts
/**
* Returns a string with `,` separators for thousands.
*/
function formatNumberString(x) {
	return String(x).replace(/\B(?<!\.\d*)(?=(\d{3})+(?!\d))/g, ",");
}
function limitDecimalsWithoutRounding(val, decimals) {
	const parts = val.split(".");
	if (parts.length !== 2) return val;
	return parts[0] + "." + parts[1].substring(0, decimals);
}
function prettifyNumber({ value, decimals, prefix, suffix, showDecimals, patchedValue }) {
	const formattedNumber = limitDecimalsWithoutRounding(formatNumberString(formatUnits(BigInt(patchedValue || value), decimals)), 4);
	return `${prefix ? `${prefix} ` : ""}${formattedNumber}${suffix ? ` ${suffix}` : ""} [${value}${showDecimals ? `, ${decimals} decimals` : ""}]`;
}
function toAddressLink(address, md, client) {
	if (!client) return address;
	const link = `${client.chain?.blockExplorers?.default.url}/address/${address}`;
	if (md) return toMarkdownLink(link, address);
	return link;
}
function toMarkdownLink(link, title) {
	return `[${title || link}](${link})`;
}
function boolToMarkdown(value) {
	return value ? ":white_check_mark:" : ":x:";
}

//#endregion
//#region formatters.ts
function getExplorerClient(chainId) {
	return getClient(chainId, {});
}
function addressLink(value, chainId) {
	return toAddressLink(value, true, getExplorerClient(chainId));
}
function isAddress(value) {
	return typeof value === "string" && /^0x[0-9a-fA-F]{40}$/.test(value);
}
const RESERVE_PERCENTAGE_FIELDS = [
	"ltv",
	"liquidationThreshold",
	"reserveFactor",
	"liquidationProtocolFee"
];
const RESERVE_BALANCE_FIELDS = ["aTokenUnderlyingBalance", "virtualBalance"];
const RESERVE_ADDRESS_FIELDS = [
	"interestRateStrategy",
	"oracle",
	"aToken",
	"variableDebtToken",
	"underlying"
];
const RESERVE_BOOL_FIELDS = [
	"isActive",
	"isFrozen",
	"isPaused",
	"isSiloed",
	"isFlashloanable",
	"isBorrowableInIsolation",
	"borrowingEnabled",
	"usageAsCollateralEnabled"
];
const reserveFormatters = {};
for (const field of RESERVE_PERCENTAGE_FIELDS) reserveFormatters[field] = (value, ctx) => prettifyNumber({
	value,
	decimals: 2,
	suffix: "%"
});
reserveFormatters["liquidationBonus"] = (value) => value === 0 ? "0 %" : `${(value - 1e4) / 100} %`;
reserveFormatters["supplyCap"] = (value, ctx) => `${value.toLocaleString("en-US")} ${ctx.reserve?.symbol ?? ""}`;
reserveFormatters["borrowCap"] = (value, ctx) => `${value.toLocaleString("en-US")} ${ctx.reserve?.symbol ?? ""}`;
reserveFormatters["debtCeiling"] = (value) => prettifyNumber({
	value,
	decimals: 2,
	suffix: "$"
});
for (const field of RESERVE_BALANCE_FIELDS) reserveFormatters[field] = (value, ctx) => prettifyNumber({
	value,
	decimals: ctx.reserve?.decimals ?? 18,
	suffix: ctx.reserve?.symbol ?? ""
});
reserveFormatters["oracleLatestAnswer"] = (value, ctx) => {
	const decimals = ctx.reserve?.oracleDecimals ?? 8;
	return formatUnits(BigInt(value), decimals);
};
for (const field of RESERVE_ADDRESS_FIELDS) reserveFormatters[field] = (value, ctx) => addressLink(value, ctx.chainId);
for (const field of RESERVE_BOOL_FIELDS) reserveFormatters[field] = (value) => boolToMarkdown(value);
const STRATEGY_RATE_FIELDS = [
	"baseVariableBorrowRate",
	"optimalUsageRatio",
	"variableRateSlope1",
	"variableRateSlope2",
	"maxVariableBorrowRate"
];
const strategyFormatters = {};
for (const field of STRATEGY_RATE_FIELDS) strategyFormatters[field] = (value) => `${formatUnits(BigInt(value), 25)} %`;
strategyFormatters["address"] = (value, ctx) => addressLink(value, ctx.chainId);
const emodeFormatters = {};
emodeFormatters["ltv"] = (value) => `${formatUnits(BigInt(value), 2)} %`;
emodeFormatters["liquidationThreshold"] = (value) => `${formatUnits(BigInt(value), 2)} %`;
emodeFormatters["liquidationBonus"] = (value) => value === 0 ? "0 %" : `${(value - 1e4) / 100} %`;
emodeFormatters["borrowableBitmap"] = (value, ctx) => {
	const indexes = bitmapToIndexes(BigInt(value));
	if (!ctx.snapshot) return indexes.join(", ");
	const reserveKeys = Object.keys(ctx.snapshot.reserves);
	return indexes.map((i) => {
		const key = reserveKeys.find((k) => ctx.snapshot.reserves[k].id === i);
		return key ? ctx.snapshot.reserves[key].symbol : `unknown(id:${i})`;
	}).join(", ");
};
emodeFormatters["collateralBitmap"] = emodeFormatters["borrowableBitmap"];
emodeFormatters["priceSource"] = (value, ctx) => addressLink(value, ctx.chainId);
const formattersMap = {
	reserve: reserveFormatters,
	strategy: strategyFormatters,
	emode: emodeFormatters
};
function formatValue$1(section, key, value, ctx) {
	const formatter = formattersMap[section][key];
	if (formatter) return formatter(value, ctx);
	if (typeof value === "boolean") return boolToMarkdown(value);
	if (typeof value === "number") return value.toLocaleString("en-US");
	if (isAddress(value)) return addressLink(value, ctx.chainId);
	return String(value);
}

//#endregion
//#region sections/strategies.ts
const IR_CHART_BASE = "https://dash.onaave.com/api/static";
const IR_CHART_PARAMS = [
	"variableRateSlope1",
	"variableRateSlope2",
	"optimalUsageRatio",
	"baseVariableBorrowRate",
	"maxVariableBorrowRate"
];
function irChartUrl(strategy) {
	return `${IR_CHART_BASE}?${IR_CHART_PARAMS.map((k) => `${k}=${strategy[k] ?? "0"}`).join("&")}`;
}
function renderIrImage(strategy) {
	return `| interestRate | ![ir](${irChartUrl(strategy)}) |\n`;
}
function renderIrDiffImages(from, to) {
	return `| interestRate | ![before](${irChartUrl(from)}) | ![after](${irChartUrl(to)}) |\n`;
}
const STRATEGY_KEY_ORDER = [
	"optimalUsageRatio",
	"maxVariableBorrowRate",
	"baseVariableBorrowRate",
	"variableRateSlope1",
	"variableRateSlope2"
];
const OMIT_KEYS$1 = ["address"];
function sortKeys$2(keys) {
	return [...keys].sort((a, b) => {
		const iA = STRATEGY_KEY_ORDER.indexOf(a);
		const iB = STRATEGY_KEY_ORDER.indexOf(b);
		if (iA === -1 && iB === -1) return a.localeCompare(b);
		if (iA === -1) return 1;
		if (iB === -1) return -1;
		return iA - iB;
	});
}
function renderStrategy(strategy, chainId) {
	const ctx = {
		chainId,
		strategy
	};
	let md = "";
	const keys = sortKeys$2(Object.keys(strategy).filter((k) => !OMIT_KEYS$1.includes(k)));
	for (const key of keys) md += `| ${key} | ${formatValue$1("strategy", key, strategy[key], ctx)} |\n`;
	return md;
}
function renderStrategyDiff(strategyDiff, chainId) {
	const from = {};
	const to = {};
	for (const key of Object.keys(strategyDiff)) {
		const val = strategyDiff[key];
		if (isChange(val)) {
			from[key] = val.from;
			to[key] = val.to;
		} else {
			from[key] = val;
			to[key] = val;
		}
	}
	const ctxFrom = {
		chainId,
		strategy: from
	};
	const ctxTo = {
		chainId,
		strategy: to
	};
	let md = "";
	const changedKeys = sortKeys$2(Object.keys(strategyDiff).filter((k) => !OMIT_KEYS$1.includes(k)).filter((key) => isChange(strategyDiff[key])));
	for (const key of changedKeys) {
		const change = strategyDiff[key];
		md += `| ${key} | ${formatValue$1("strategy", key, change.from, ctxFrom)} | ${formatValue$1("strategy", key, change.to, ctxTo)} |\n`;
	}
	return md;
}

//#endregion
//#region sections/reserves.ts
const RESERVE_KEY_ORDER = [
	"id",
	"symbol",
	"decimals",
	"isActive",
	"isFrozen",
	"isPaused",
	"supplyCap",
	"borrowCap",
	"debtCeiling",
	"isSiloed",
	"isFlashloanable",
	"oracle",
	"oracleDecimals",
	"oracleDescription",
	"oracleName",
	"oracleLatestAnswer",
	"usageAsCollateralEnabled",
	"ltv",
	"liquidationThreshold",
	"liquidationBonus",
	"liquidationProtocolFee",
	"reserveFactor",
	"aToken",
	"aTokenName",
	"aTokenSymbol",
	"variableDebtToken",
	"variableDebtTokenName",
	"variableDebtTokenSymbol",
	"borrowingEnabled",
	"isBorrowableInIsolation",
	"interestRateStrategy",
	"aTokenUnderlyingBalance",
	"virtualBalance"
];
const OMIT_IN_HEADER = ["underlying", "symbol"];
function sortKeys$1(keys) {
	return [...keys].sort((a, b) => {
		const iA = RESERVE_KEY_ORDER.indexOf(a);
		const iB = RESERVE_KEY_ORDER.indexOf(b);
		if (iA === -1 && iB === -1) return a.localeCompare(b);
		if (iA === -1) return 1;
		if (iB === -1) return -1;
		return iA - iB;
	});
}
function reserveHeadline(reserve, chainId) {
	const client = getClient(chainId, {});
	const link = toAddressLink(reserve.underlying, true, client);
	return `#### ${reserve.symbol} (${link})\n\n`;
}
function renderReserveTable(reserve, chainId) {
	const ctx = {
		chainId,
		reserve
	};
	let md = reserveHeadline(reserve, chainId);
	md += "| description | value |\n| --- | --- |\n";
	const keys = sortKeys$1(Object.keys(reserve).filter((k) => !OMIT_IN_HEADER.includes(k)));
	for (const key of keys) {
		const value = reserve[key];
		md += `| ${key} | ${formatValue$1("reserve", key, value, ctx)} |\n`;
	}
	return md;
}
function renderReserveDiffTable(reserveDiff, chainId) {
	const from = {};
	const to = {};
	for (const key of Object.keys(reserveDiff)) {
		const val = reserveDiff[key];
		if (isChange(val)) {
			from[key] = val.from;
			to[key] = val.to;
		} else {
			from[key] = val;
			to[key] = val;
		}
	}
	const ctxFrom = {
		chainId,
		reserve: from
	};
	const ctxTo = {
		chainId,
		reserve: to
	};
	let md = reserveHeadline(from, chainId);
	md += "| description | value before | value after |\n| --- | --- | --- |\n";
	const changedKeys = sortKeys$1(Object.keys(reserveDiff).filter((key) => isChange(reserveDiff[key])));
	for (const key of changedKeys) {
		const change = reserveDiff[key];
		const fromVal = formatValue$1("reserve", key, change.from, ctxFrom);
		const toVal = formatValue$1("reserve", key, change.to, ctxTo);
		md += `| ${key} | ${fromVal} | ${toVal} |\n`;
	}
	return md;
}
function renderReservesSection(diffResult, pre, post) {
	if (!diffResult.reserves) return "";
	const reservesDiff = diffResult.reserves;
	const added = [];
	const removed = [];
	const altered = [];
	for (const key of Object.keys(reservesDiff)) {
		const entry = reservesDiff[key];
		if (isChange(entry) && entry.from === null && entry.to !== null) {
			let report = renderReserveTable(entry.to, pre.chainId);
			if (post.strategies[key]) {
				report += renderStrategy(post.strategies[key], pre.chainId);
				report += renderIrImage(post.strategies[key]);
			}
			added.push(report);
			continue;
		}
		if (isChange(entry) && entry.from !== null && entry.to === null) {
			removed.push(renderReserveTable(entry.from, pre.chainId));
			continue;
		}
		if (typeof entry === "object" && !isChange(entry)) {
			const reserveDiff = entry;
			const hasReserveChanges = hasChanges(reserveDiff);
			const preStrategy = pre.strategies[key];
			const postStrategy = post.strategies[key];
			const strategyChanged = preStrategy && postStrategy && JSON.stringify(preStrategy) !== JSON.stringify(postStrategy);
			if (!hasReserveChanges && !strategyChanged) continue;
			let report = "";
			if (hasReserveChanges) report += renderReserveDiffTable(reserveDiff, pre.chainId);
			if (strategyChanged) {
				const stratDiff = diff(preStrategy, postStrategy);
				report += renderStrategyDiff(stratDiff, pre.chainId);
				report += renderIrDiffImages(preStrategy, postStrategy);
			}
			if (report) altered.push(report);
		}
	}
	if (!added.length && !removed.length && !altered.length) return "";
	let md = "## Reserve changes\n\n";
	if (added.length) {
		md += `### Reserves added\n\n`;
		md += added.join("\n\n");
		md += "\n\n";
	}
	if (altered.length) {
		md += `### Reserves altered\n\n`;
		md += altered.join("\n\n");
		md += "\n\n";
	}
	if (removed.length) {
		md += `### Reserves removed\n\n`;
		md += removed.join("\n\n");
		md += "\n\n";
	}
	return md;
}

//#endregion
//#region sections/emodes.ts
const EMODE_KEY_ORDER = [
	"eModeCategory",
	"label",
	"ltv",
	"liquidationThreshold",
	"liquidationBonus",
	"priceSource",
	"borrowableBitmap",
	"collateralBitmap"
];
const OMIT_KEYS = ["eModeCategory"];
function sortKeys(keys) {
	return [...keys].sort((a, b) => {
		const iA = EMODE_KEY_ORDER.indexOf(a);
		const iB = EMODE_KEY_ORDER.indexOf(b);
		if (iA === -1 && iB === -1) return a.localeCompare(b);
		if (iA === -1) return 1;
		if (iB === -1) return -1;
		return iA - iB;
	});
}
function renderEmodeDiffTable(emodeDiff, pre, post) {
	const chainId = post.chainId;
	let md = "| description | value before | value after |\n| --- | --- | --- |\n";
	const keys = sortKeys(Object.keys(emodeDiff).filter((k) => !OMIT_KEYS.includes(k)));
	for (const key of keys) {
		const val = emodeDiff[key];
		if (isChange(val)) {
			const ctxPre = {
				chainId,
				emode: emodeDiff,
				snapshot: pre
			};
			const ctxPost = {
				chainId,
				emode: emodeDiff,
				snapshot: post
			};
			const fromVal = val.from != null ? formatValue$1("emode", key, val.from, ctxPre) : "-";
			const toVal = val.to != null ? formatValue$1("emode", key, val.to, ctxPost) : "-";
			md += `| ${key} | ${fromVal} | ${toVal} |\n`;
		}
	}
	return md;
}
function renderEmodesSection(diffResult, pre, post) {
	if (!diffResult.eModes) return "";
	const emodesDiff = diffResult.eModes;
	let md = "";
	for (const emodeId of Object.keys(emodesDiff)) {
		const postEmode = post.eModes[emodeId];
		const preEmode = pre.eModes[emodeId];
		const emodeFullDiff = diff(preEmode || {}, postEmode || {});
		if (!hasChanges(emodeFullDiff)) continue;
		const label = postEmode?.label || preEmode?.label || "Unknown";
		const category = postEmode?.eModeCategory ?? preEmode?.eModeCategory ?? emodeId;
		md += `### EMode: ${label} (id: ${category})\n\n`;
		md += renderEmodeDiffTable(emodeFullDiff, pre, post);
		md += "\n\n";
	}
	if (!md) return "";
	return "## EMode changes\n\n" + md;
}

//#endregion
//#region sections/pool-config.ts
function renderPoolConfigSection(diffResult, chainId) {
	if (!diffResult.poolConfig) return "";
	const configDiff = diffResult.poolConfig;
	const changedKeys = Object.keys(configDiff).filter((key) => isChange(configDiff[key]));
	if (!changedKeys.length) return "";
	const client = getClient(chainId, {});
	let md = "## Pool config changes\n\n";
	md += "| description | value before | value after |\n| --- | --- | --- |\n";
	for (const key of changedKeys) {
		const change = configDiff[key];
		const from = toAddressLink(change.from, true, client);
		const to = toAddressLink(change.to, true, client);
		md += `| ${key} | ${from} | ${to} |\n`;
	}
	md += "\n\n";
	return md;
}

//#endregion
//#region utils/address.ts
/**
* Checks if address is listed in the aave-address-book.
* Returns found paths or undefined.
*/
function isKnownAddress(value, chainId) {
	const results = findObjectPaths(Object.keys(addresses).reduce((acc, key) => {
		if (addresses[key].CHAIN_ID === chainId) {
			const chainAddresses = { ...addresses[key] };
			if (chainAddresses.E_MODES) delete chainAddresses.E_MODES;
			acc[key] = chainAddresses;
		}
		return acc;
	}, {}), { value: getAddress(value) });
	if (typeof results === "string") return [results];
	return results;
}

//#endregion
//#region sections/raw.ts
function renderRawSection(raw, chainId) {
	if (!raw) return "";
	const contracts = Object.keys(raw);
	if (!contracts.length) return "";
	let md = "## Raw storage changes\n\n";
	for (const address of contracts) {
		const entry = raw[address];
		if (!entry) continue;
		const knownName = isKnownAddress(address, chainId);
		const label = entry.label || (knownName ? knownName.join(", ") : null);
		const heading = label ? `${address} (${label})` : address;
		md += `### ${heading}\n\n`;
		if (entry.balanceDiff) md += `**Balance diff**: ${entry.balanceDiff.previousValue} → ${entry.balanceDiff.newValue}\n\n`;
		if (entry.nonceDiff) md += `**Nonce diff**: ${entry.nonceDiff.previousValue} → ${entry.nonceDiff.newValue}\n\n`;
		const slots = Object.keys(entry.stateDiff);
		if (slots.length) {
			md += "| slot | previous value | new value |\n| --- | --- | --- |\n";
			for (const slot of slots) {
				const slotDiff = entry.stateDiff[slot];
				const slotLabel = slotDiff.label ? ` (${slotDiff.label})` : "";
				md += `| ${slot}${slotLabel} | ${slotDiff.previousValue} | ${slotDiff.newValue} |\n`;
			}
			md += "\n";
		}
	}
	md += "\n";
	return md;
}

//#endregion
//#region utils/eventDb.json
var eventDb_default = [
	{
		"type": "event",
		"name": "RoleGranted",
		"inputs": [
			{
				"name": "role",
				"type": "bytes32",
				"indexed": true,
				"internalType": "bytes32"
			},
			{
				"name": "account",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "sender",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			}
		]
	},
	{
		"type": "event",
		"name": "Approval",
		"inputs": [
			{
				"name": "owner",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "spender",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "value",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "Transfer",
		"inputs": [
			{
				"name": "from",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "to",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "value",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "RegistrationRequested",
		"inputs": [
			{
				"name": "hash",
				"type": "bytes32",
				"indexed": true,
				"internalType": "bytes32"
			},
			{
				"name": "name",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "encryptedEmail",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			},
			{
				"name": "upkeepContract",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "gasLimit",
				"type": "uint32",
				"indexed": false,
				"internalType": "uint32"
			},
			{
				"name": "adminAddress",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "triggerType",
				"type": "uint8",
				"indexed": false,
				"internalType": "uint8"
			},
			{
				"name": "triggerConfig",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			},
			{
				"name": "offchainConfig",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			},
			{
				"name": "checkData",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			},
			{
				"name": "amount",
				"type": "uint96",
				"indexed": false,
				"internalType": "uint96"
			}
		]
	},
	{
		"type": "event",
		"name": "UpkeepRegistered",
		"inputs": [
			{
				"name": "id",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			},
			{
				"name": "performGas",
				"type": "uint32",
				"indexed": false,
				"internalType": "uint32"
			},
			{
				"name": "admin",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			}
		]
	},
	{
		"type": "event",
		"name": "UpkeepCheckDataSet",
		"inputs": [{
			"name": "id",
			"type": "uint256",
			"indexed": true,
			"internalType": "uint256"
		}, {
			"name": "newCheckData",
			"type": "bytes",
			"indexed": false,
			"internalType": "bytes"
		}]
	},
	{
		"type": "event",
		"name": "UpkeepTriggerConfigSet",
		"inputs": [{
			"name": "id",
			"type": "uint256",
			"indexed": true,
			"internalType": "uint256"
		}, {
			"name": "triggerConfig",
			"type": "bytes",
			"indexed": false,
			"internalType": "bytes"
		}]
	},
	{
		"type": "event",
		"name": "UpkeepOffchainConfigSet",
		"inputs": [{
			"name": "id",
			"type": "uint256",
			"indexed": true,
			"internalType": "uint256"
		}, {
			"name": "offchainConfig",
			"type": "bytes",
			"indexed": false,
			"internalType": "bytes"
		}]
	},
	{
		"type": "event",
		"name": "Transfer",
		"inputs": [
			{
				"name": "from",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "to",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "value",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "data",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			}
		]
	},
	{
		"type": "event",
		"name": "FundsAdded",
		"inputs": [
			{
				"name": "id",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			},
			{
				"name": "from",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "amount",
				"type": "uint96",
				"indexed": false,
				"internalType": "uint96"
			}
		]
	},
	{
		"type": "event",
		"name": "RegistrationApproved",
		"inputs": [
			{
				"name": "hash",
				"type": "bytes32",
				"indexed": true,
				"internalType": "bytes32"
			},
			{
				"name": "displayName",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "upkeepId",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "KeeperRegistered",
		"inputs": [
			{
				"name": "id",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			},
			{
				"name": "upkeep",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "amount",
				"type": "uint96",
				"indexed": true,
				"internalType": "uint96"
			}
		]
	},
	{
		"type": "event",
		"name": "ExecutedAction",
		"inputs": [
			{
				"name": "target",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "value",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "signature",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "data",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			},
			{
				"name": "executionTime",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "withDelegatecall",
				"type": "bool",
				"indexed": false,
				"internalType": "bool"
			},
			{
				"name": "resultData",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			}
		]
	},
	{
		"type": "event",
		"name": "PayloadExecuted",
		"inputs": [{
			"name": "payloadId",
			"type": "uint40",
			"indexed": false,
			"internalType": "uint40"
		}]
	},
	{
		"type": "event",
		"name": "Mint",
		"inputs": [
			{
				"name": "caller",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "onBehalfOf",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "value",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "balanceIncrease",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "index",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "BalanceTransfer",
		"inputs": [
			{
				"name": "from",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "to",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "value",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "index",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "CancelStream",
		"inputs": [
			{
				"name": "streamId",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			},
			{
				"name": "sender",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "recipient",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "senderBalance",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "recipientBalance",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "CreateStream",
		"inputs": [
			{
				"name": "streamId",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			},
			{
				"name": "sender",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "recipient",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "deposit",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "tokenAddress",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "startTime",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "stopTime",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "SupplyCapChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldSupplyCap",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "newSupplyCap",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "BorrowCapChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldBorrowCap",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "newBorrowCap",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "BridgeAdapterUpdated",
		"inputs": [
			{
				"name": "destinationChainId",
				"type": "uint256",
				"indexed": true,
				"internalType": "uint256"
			},
			{
				"name": "bridgeAdapter",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "destinationBridgeAdapter",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "allowed",
				"type": "bool",
				"indexed": true,
				"internalType": "bool"
			}
		]
	},
	{
		"type": "event",
		"name": "AssetSourceUpdated",
		"inputs": [{
			"name": "asset",
			"type": "address",
			"indexed": true,
			"internalType": "address"
		}, {
			"name": "source",
			"type": "address",
			"indexed": true,
			"internalType": "address"
		}]
	},
	{
		"type": "event",
		"name": "Initialized",
		"inputs": [
			{
				"name": "underlyingAsset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "pool",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "treasury",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "incentivesController",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "aTokenDecimals",
				"type": "uint8",
				"indexed": false,
				"internalType": "uint8"
			},
			{
				"name": "aTokenName",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "aTokenSymbol",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "params",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			}
		]
	},
	{
		"type": "event",
		"name": "Initialized",
		"inputs": [
			{
				"name": "underlyingAsset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "pool",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "incentivesController",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "debtTokenDecimals",
				"type": "uint8",
				"indexed": false,
				"internalType": "uint8"
			},
			{
				"name": "debtTokenName",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "debtTokenSymbol",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			},
			{
				"name": "params",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			}
		]
	},
	{
		"type": "event",
		"name": "RateDataUpdate",
		"inputs": [
			{
				"name": "reserve",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "optimalUsageRatio",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "baseVariableBorrowRate",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "variableRateSlope1",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "variableRateSlope2",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "ReserveInitialized",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "aToken",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "stableDebtToken",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "variableDebtToken",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "interestRateStrategyAddress",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			}
		]
	},
	{
		"type": "event",
		"name": "ReserveInterestRateDataChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "strategy",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "data",
				"type": "bytes",
				"indexed": false,
				"internalType": "bytes"
			}
		]
	},
	{
		"type": "event",
		"name": "ReserveBorrowing",
		"inputs": [{
			"name": "asset",
			"type": "address",
			"indexed": true,
			"internalType": "address"
		}, {
			"name": "enabled",
			"type": "bool",
			"indexed": false,
			"internalType": "bool"
		}]
	},
	{
		"type": "event",
		"name": "BorrowableInIsolationChanged",
		"inputs": [{
			"name": "asset",
			"type": "address",
			"indexed": false,
			"internalType": "address"
		}, {
			"name": "borrowable",
			"type": "bool",
			"indexed": false,
			"internalType": "bool"
		}]
	},
	{
		"type": "event",
		"name": "SiloedBorrowingChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldState",
				"type": "bool",
				"indexed": false,
				"internalType": "bool"
			},
			{
				"name": "newState",
				"type": "bool",
				"indexed": false,
				"internalType": "bool"
			}
		]
	},
	{
		"type": "event",
		"name": "ReserveFactorChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldReserveFactor",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "newReserveFactor",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "ReserveDataUpdated",
		"inputs": [
			{
				"name": "reserve",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "liquidityRate",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "stableBorrowRate",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "variableBorrowRate",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "liquidityIndex",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "variableBorrowIndex",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "ReserveFlashLoaning",
		"inputs": [{
			"name": "asset",
			"type": "address",
			"indexed": true,
			"internalType": "address"
		}, {
			"name": "enabled",
			"type": "bool",
			"indexed": false,
			"internalType": "bool"
		}]
	},
	{
		"type": "event",
		"name": "CollateralConfigurationChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "ltv",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "liquidationThreshold",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "liquidationBonus",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "DebtCeilingChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldDebtCeiling",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "newDebtCeiling",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "LiquidationProtocolFeeChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldFee",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "newFee",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			}
		]
	},
	{
		"type": "event",
		"name": "EModeCategoryAdded",
		"inputs": [
			{
				"name": "categoryId",
				"type": "uint8",
				"indexed": true,
				"internalType": "uint8"
			},
			{
				"name": "ltv",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "liquidationThreshold",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "liquidationBonus",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "oracle",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "label",
				"type": "string",
				"indexed": false,
				"internalType": "string"
			}
		]
	},
	{
		"type": "event",
		"name": "AssetCollateralInEModeChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "categoryId",
				"type": "uint8",
				"indexed": false,
				"internalType": "uint8"
			},
			{
				"name": "collateral",
				"type": "bool",
				"indexed": false,
				"internalType": "bool"
			}
		]
	},
	{
		"type": "event",
		"name": "AssetBorrowableInEModeChanged",
		"inputs": [
			{
				"name": "asset",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "categoryId",
				"type": "uint8",
				"indexed": false,
				"internalType": "uint8"
			},
			{
				"name": "borrowable",
				"type": "bool",
				"indexed": false,
				"internalType": "bool"
			}
		]
	},
	{
		"type": "event",
		"name": "Supply",
		"inputs": [
			{
				"name": "reserve",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "user",
				"type": "address",
				"indexed": false,
				"internalType": "address"
			},
			{
				"name": "onBehalfOf",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "amount",
				"type": "uint256",
				"indexed": false,
				"internalType": "uint256"
			},
			{
				"name": "referralCode",
				"type": "uint16",
				"indexed": true,
				"internalType": "uint16"
			}
		]
	},
	{
		"type": "event",
		"name": "EmissionAdminUpdated",
		"inputs": [
			{
				"name": "reward",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "oldAdmin",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			},
			{
				"name": "newAdmin",
				"type": "address",
				"indexed": true,
				"internalType": "address"
			}
		]
	}
];

//#endregion
//#region sections/logs.ts
function renderLogsSection(logs) {
	if (!logs || !logs.length) return "";
	const parsed = parseLogs({
		logs: logs.map((log) => ({
			topics: log.topics,
			data: log.data,
			address: log.emitter
		})),
		eventDb: eventDb_default
	});
	let md = "## Event logs\n\n";
	md += "| index | emitter | event |\n| --- | --- | --- |\n";
	for (let i = 0; i < parsed.length; i++) {
		const log = parsed[i];
		const emitter = logs[i].emitter;
		if (log.eventName) {
			const args = log.args ? formatArgs(log.args) : "";
			md += `| ${i} | ${emitter} | ${log.eventName}(${args}) |\n`;
		} else {
			const topics = logs[i].topics.map((t) => `\`${t}\``).join(", ");
			const data = logs[i].data.length > 66 ? `${logs[i].data.slice(0, 66)}...` : logs[i].data;
			md += `| ${i} | ${emitter} | topics: ${topics}, data: \`${data}\` |\n`;
		}
	}
	md += "\n";
	return md;
}
function formatArgs(args) {
	if (Array.isArray(args)) return args.map((v) => formatValue(v)).join(", ");
	if (typeof args === "object" && args !== null) return Object.entries(args).map(([k, v]) => `${k}: ${formatValue(v)}`).join(", ");
	return String(args);
}
function formatValue(v) {
	if (typeof v === "bigint") return v.toString();
	if (typeof v === "string") return v;
	if (typeof v === "boolean") return String(v);
	if (Array.isArray(v)) return `[${v.map(formatValue).join(", ")}]`;
	if (typeof v === "object" && v !== null) return JSON.stringify(v);
	return String(v);
}

//#endregion
//#region protocol-diff.ts
/**
* Diff two Aave V3 protocol snapshots and produce a formatted markdown report.
*
* The `raw` and `logs` sections only exist in the "after" snapshot and are
* rendered as-is (they already represent the diff / changes).
*/
function diffSnapshots(before, after) {
	let raw;
	let logs;
	const postCopy = { ...after };
	if (postCopy.raw) {
		raw = postCopy.raw;
		delete postCopy.raw;
	}
	if (postCopy.logs) {
		logs = [...postCopy.logs];
		delete postCopy.logs;
	}
	const diffResult = diff(before, postCopy);
	let md = "";
	md += renderReservesSection(diffResult, before, after);
	md += renderEmodesSection(diffResult, before, after);
	md += renderPoolConfigSection(diffResult, after.chainId);
	md += renderLogsSection(logs);
	md += renderRawSection(raw, after.chainId);
	const diffWithoutUnchanged = diff(before, postCopy, true);
	md += `## Raw diff\n\n\`\`\`json\n${JSON.stringify(diffWithoutUnchanged, null, 2)}\n\`\`\`\n`;
	return md;
}

//#endregion
export { isChange as i, diff as n, hasChanges as r, diffSnapshots as t };