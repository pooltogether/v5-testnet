import * as fs from 'fs';
import npmPackage from '../../package.json';

import {
  Contract,
  ContractList,
  VaultInfo,
  Version
} from './types';

const versionSplit = npmPackage.version.split('.');
const patchSplit = versionSplit[2].split('-');

const PACKAGE_VERSION: Version = {
  major: Number(versionSplit[0]),
  minor: Number(versionSplit[1]),
  patch: Number(patchSplit[0]),
};

const renameType = (type: string) => {
  switch (type) {
    case 'YieldVaultMintRate':
      return 'YieldVault';
    case 'VaultMintRate':
      return 'Vault';
    default:
      return type;
  }
}

const getUnderlyingAsset = (transactions: any, underlyingAssetAddress: string) => {
  const deployArguments = transactions.find((transaction: { contractAddress: string; }) => transaction.contractAddress === underlyingAssetAddress).arguments;

  return {
    name: deployArguments[0],
    symbol: deployArguments[1],
    decimals: Number(deployArguments[2]),
  }
}

const generateVaultTokens = (
  transactions: any,
  chainId: number,
  address: `0x${string}`,
  deployArguments: string[]
): VaultInfo[] => {
  const name = deployArguments[1];
  const underlyingAssetAddress = deployArguments[0] as `0x${string}`;
  const underlyingAsset = getUnderlyingAsset(transactions, underlyingAssetAddress);

  return [{
    chainId,
    address,
    name,
    decimals: underlyingAsset.decimals,
    symbol: deployArguments[2],
    extensions: {
      yieldSource: 'YieldVault',
      underlyingAsset: {
        chainId,
        address: underlyingAssetAddress,
        symbol: underlyingAsset.symbol,
        name: underlyingAsset.name,
        decimals: underlyingAsset.decimals,
      }
    }
  }]
}

const formatContract = (transactions: any, chainId: number, name: string, address: `0x${string}`, deployArguments: string[]): Contract => {
  const regex = /V[1-9+]((.{0,2}[0-9+]){0,2})$/g;
  const version = name.match(regex)?.[0]?.slice(1).split('.') || [1, 0, 0];
  const type = name.split(regex)[0];

  const defaultContract = {
    chainId,
    address,
    version: {
      major: Number(version[0]),
      minor: Number(version[1]) || 0,
      patch: Number(version[2]) || 0,
    },
    type: renameType(type),
  }

  if (type === 'VaultMintRate') {
    return {
      ...defaultContract,
      tokens: generateVaultTokens(transactions, chainId, address, deployArguments)
    }
  } else {
    return defaultContract;
  }
};

export const generateContractList = (deploymentPaths: string[]): ContractList => {
  const contractList: ContractList = {
    name: 'Hyperstructure Testnet',
    version: PACKAGE_VERSION,
    contracts: [],
  };

  deploymentPaths.forEach((deploymentPath) => {
    const deploymentBlob = JSON.parse(
      fs.readFileSync(`${deploymentPath}/run-latest.json`, 'utf8'),
    );

    const chainId = deploymentBlob.chain;
    const transactions = deploymentBlob.transactions;

    transactions.forEach(({ transactionType, contractName, contractAddress, arguments: deployArguments, additionalContracts }) => {
      const createdContract = additionalContracts[0];

      if (transactionType == 'CALL' && createdContract && createdContract.transactionType === 'CREATE') {
        transactionType = 'CREATE';
        contractAddress = createdContract.address;

        if (contractName === 'LiquidationPairFactory') {
          contractName = 'LiquidationPair';
        }
      }

      if (transactionType === 'CREATE') {
        contractList.contracts.push(formatContract(transactions, chainId, contractName, contractAddress, deployArguments));
      }
    });
  });

  return contractList;
}

export const writeContractList = (contractList: ContractList, fileName: string) => {
  fs.writeFile(`${__dirname}/../../${fileName}.json`, JSON.stringify(contractList), (err) => {
    if (err) {
      console.error(err);
      return;
    }
  });
}
