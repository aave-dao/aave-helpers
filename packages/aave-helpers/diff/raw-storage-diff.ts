import { writeFileSync, mkdirSync } from 'fs';
import { bytes32ToAddress } from '../utils/storageSlots';
import { RawStorage, SlotDiff } from './snapshot-types';
import { isKnownAddress } from '../utils/address';
import { Address, getContract, isAddress, zeroHash } from 'viem';
import { IPool_ABI } from '@bgd-labs/aave-address-book/abis';
import {
  getClient,
  BlockscoutStyleSourceCode,
  diffCode,
  getSourceCode,
  parseBlockscoutStyleSourceCode,
  parseEtherscanStyleSourceCode,
  StandardJsonInput,
} from '@bgd-labs/toolbox';

export async function diffSlot(chainId: number, address: Address, slot: SlotDiff) {
  const fromAddress = isAddress(slot.previousValue)
    ? slot.previousValue
    : bytes32ToAddress(slot.previousValue);
  const toAddress = isAddress(slot.newValue) ? slot.newValue : bytes32ToAddress(slot.newValue);
  if (slot.previousValue != zeroHash) {
    const sources = await Promise.all([
      getSourceCode({
        chainId: Number(chainId),
        address: fromAddress,
        apiKey: process.env.ETHERSCAN_API_KEY,
        apiUrl: process.env.EXPLORER_PROXY,
      }),
      getSourceCode({
        chainId: Number(chainId),
        address: toAddress,
        apiKey: process.env.ETHERSCAN_API_KEY,
        apiUrl: process.env.EXPLORER_PROXY,
      }),
    ]);
    const source1: StandardJsonInput = (sources[0] as BlockscoutStyleSourceCode).AdditionalSources
      ? parseBlockscoutStyleSourceCode(sources[0] as BlockscoutStyleSourceCode)
      : parseEtherscanStyleSourceCode(sources[0].SourceCode);
    const source2: StandardJsonInput = (sources[0] as BlockscoutStyleSourceCode).AdditionalSources
      ? parseBlockscoutStyleSourceCode(sources[1] as BlockscoutStyleSourceCode)
      : parseEtherscanStyleSourceCode(sources[1].SourceCode);
    const diff = await diffCode(source1, source2);
    const flat = Object.keys(diff).reduce((acc, key) => {
      acc += diff[key];
      return acc;
    }, '');
    mkdirSync('./diffs', { recursive: true });
    writeFileSync(`./diffs/${chainId}_${address}_${fromAddress}_${toAddress}.diff`, flat, {});
  }
}

export async function diffRawStorage(chainId: number, raw: RawStorage) {
  // ERC1967 slot https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/ERC1967/ERC1967Utils.sol#L21C53-L21C119
  const erc1967ImplSlot = '0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc';
  const erc1967AdminSlot = '0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103';
  await Promise.all(
    (Object.keys(raw) as (keyof typeof raw)[]).map(async (contract) => {
      if (raw[contract]) {
        const contractName = isKnownAddress(contract, chainId);
        // label known contracts if no label was set on foundry
        if (!raw[contract].label) {
          if (contractName) raw[contract].label = contractName.join(', ');
        }

        // create contract diff if storage changed
        if (raw[contract].stateDiff[erc1967ImplSlot]) {
          raw[contract].stateDiff[erc1967ImplSlot].label = 'Implementation slot';
          try {
            await diffSlot(chainId, contract, raw[contract].stateDiff[erc1967ImplSlot]);
          } catch (e) {
            console.log('error diffing erc1967ImplSlot');
          }
        }

        // admin slot
        if (raw[contract].stateDiff[erc1967AdminSlot]) {
          raw[contract].stateDiff[erc1967ImplSlot].label = 'Admin slot';
          // ... we might want to fetch the owner in that case
        }

        if (raw[contract].stateDiff[erc1967ImplSlot] && contractName) {
          const path = contractName[0].split('.');
          // Diff code logic libraries
          if (path[path.length - 1] === 'POOL') {
            const oldPool = getContract({
              client: getClient(chainId, {
                providerConfig: { alchemyKey: process.env.ALCHEMY_API_KEY },
              }) as any,
              abi: IPool_ABI,
              address: bytes32ToAddress(raw[contract].stateDiff[erc1967ImplSlot].previousValue),
            });
            const newPool = getContract({
              client: getClient(chainId, {}),
              abi: IPool_ABI,
              address: bytes32ToAddress(raw[contract].stateDiff[erc1967ImplSlot].newValue),
            });
            const addresses = await Promise.all([
              oldPool.read.getSupplyLogic(),
              newPool.read.getSupplyLogic(),
              oldPool.read.getBorrowLogic(),
              newPool.read.getBorrowLogic(),
              oldPool.read.getLiquidationLogic(),
              newPool.read.getLiquidationLogic(),
              oldPool.read.getPoolLogic(),
              newPool.read.getPoolLogic(),
              oldPool.read.getFlashLoanLogic(),
              newPool.read.getFlashLoanLogic(),
            ]);
            for (let i = 0; i < addresses.length; i = i + 2) {
              try {
                diffSlot(chainId, contract, {
                  previousValue: addresses[i],
                  newValue: addresses[i + 1],
                });
              } catch (e) {
                console.log('error diffing logic library');
              }
            }
          }
        }
      }
    })
  );
}
