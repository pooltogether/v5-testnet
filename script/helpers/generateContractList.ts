import * as fs from 'fs';
import npmPackage from '../../package.json';

type Version = {
  major: number;
  minor: number;
  patch: number;
}

type Contract = {
  chainId: number;
  address: string;
  version: Version;
  type: string;
}

type ContractList = {
  name: string;
  version: Version;
  contracts: Contract[]
}

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

const formatContract = (chainId: number, name: string, address: string): Contract => {
  const regex = /V[1-9+]((.{0,2}[0-9+]){0,2})$/g;
  const version = name.match(regex)?.[0]?.slice(1).split('.') || [1, 0, 0];

  return {
    chainId,
    address,
    version: {
      major: Number(version[0]),
      minor: Number(version[1]) || 0,
      patch: Number(version[2]) || 0,
    },
    type: renameType(name.split(regex)[0]),
  };
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

    deploymentBlob.transactions.forEach(({ transactionType, contractName, contractAddress, additionalContracts }) => {
      const createdContract = additionalContracts[0];

      if (transactionType == 'CALL' && createdContract && createdContract.transactionType === 'CREATE') {
        transactionType = 'CREATE';
        contractAddress = createdContract.address;

        if (contractName === 'LiquidationPairFactory') {
          contractName = 'LiquidationPair';
        }
      }

      if (transactionType === 'CREATE') {
        contractList.contracts.push(formatContract(chainId, contractName, contractAddress));
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
