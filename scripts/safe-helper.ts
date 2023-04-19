import Safe from '@safe-global/safe-core-sdk';
import { OperationType, SafeTransactionDataPartial } from '@safe-global/safe-core-sdk-types';
import EthersAdapter from '@safe-global/safe-ethers-lib';
import SafeServiceClient from '@safe-global/safe-service-client';
import { ethers } from 'ethers';
import { LedgerSigner } from '@ethersproject/hardware-wallets';

import dotenv from 'dotenv';
dotenv.config();

// original: https://github.com/safe-global/safe-core-sdk/tree/main/playground

interface Config {
  RPC_URL: string | undefined;
  SIGNER_ADDRESS_PRIVATE_KEY: string | undefined;
  MNEMONIC_INDEX: string;
  TX_SERVICE_URL: string;
}

const config: Config = {
  RPC_URL: process.env.RPC_URL,
  SIGNER_ADDRESS_PRIVATE_KEY: process.env.PRIVATE_KEY,
  MNEMONIC_INDEX: process.env.MNEMONIC_INDEX || '0',
  TX_SERVICE_URL: process.env.TX_SERVICE_URL || '', // Check https://docs.safe.global/backend/available-services
};

type ChainId = 1;

const RPCS: Record<ChainId, string> = {
  1: process.env.RPC_MAINNET as string,
};

const TX_SERVICE_URLS: Record<ChainId, string> = {
  1: 'https://safe-transaction-mainnet.safe.global/',
};

async function proposeTransaction() {
  const sender = process.argv[2];
  // TODO: validate is address & contract (should be safe)
  const to = process.argv[3];
  // TODO: validate is address
  const data = process.argv[4];
  // TODO: validate is bytes
  const chainId = Number(process.argv[5]) as ChainId;
  if (!Object.keys(OperationType).includes(process.argv[6]))
    throw new Error('UNSUPPORTED_OPERATION_TYPE');
  const calltype = OperationType[process.argv[6] as keyof OperationType] as OperationType;

  const rpc = RPCS[chainId];
  const serviceUrl = TX_SERVICE_URLS[chainId];

  const provider = new ethers.providers.JsonRpcProvider(rpc);
  // Private key signer
  // const signer = new ethers.Wallet(config.SIGNER_ADDRESS_PRIVATE_KEY, provider);

  // Ledger signer
  const signer = new LedgerSigner(provider, 'default', getLedgerPath(config.MNEMONIC_INDEX));

  // Create EthAdapter instance
  const ethAdapter = new EthersAdapter({
    ethers,
    signerOrProvider: signer,
  });

  // Create Safe instance
  const safe = await Safe.create({
    ethAdapter,
    safeAddress: sender,
  });

  // Create Safe Service Client instance
  const service = new SafeServiceClient({
    txServiceUrl: serviceUrl,
    ethAdapter,
  });

  // Create transaction
  const safeTransactionData: SafeTransactionDataPartial = {
    to: to,
    value: '0', // 0 wei
    data: data,
    operation: calltype,
  };

  const safeTransaction = await safe.createTransaction({ safeTransactionData });

  const senderAddress = await signer.getAddress();
  const safeTxHash = await safe.getTransactionHash(safeTransaction);
  const signature = await safe.signTransactionHash(safeTxHash);

  // Propose transaction to the service
  await service.proposeTransaction({
    safeAddress: sender,
    safeTransactionData: safeTransaction.data,
    safeTxHash,
    senderAddress,
    senderSignature: signature.data,
  });
}

function getLedgerPath(mnemonicIndex: string) {
  return `m/44'/60'/${mnemonicIndex}'/0/0`;
}

proposeTransaction();
