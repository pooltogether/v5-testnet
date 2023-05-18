import * as fs from "fs";
import npmPackage from "../../package.json";

import { Contract, ContractList, VaultInfo, VaultList, Version } from "./types";

const versionSplit = npmPackage.version.split(".");
const patchSplit = versionSplit[2].split("-");

const PACKAGE_VERSION: Version = {
  major: Number(versionSplit[0]),
  minor: Number(versionSplit[1]),
  patch: Number(patchSplit[0]),
};

export const rootFolder = `${__dirname}/../..`;

const renameType = (type: string) => {
  switch (type) {
    case "YieldVaultMintRate":
      return "YieldVault";
    case "VaultMintRate":
      return "Vault";
    default:
      return type;
  }
};

const getAbi = (type: string) =>
  JSON.parse(fs.readFileSync(`${rootFolder}/out/${type}.sol/${type}.json`, "utf8")).abi;

const getBlob = (path: string) => JSON.parse(fs.readFileSync(`${path}/run-latest.json`, "utf8"));

const getUnderlyingAsset = (transactions: any, underlyingAssetAddress: string) => {
  const deployArguments = transactions.find(
    (transaction: { contractAddress: string }) =>
      transaction.contractAddress === underlyingAssetAddress
  ).arguments;

  return {
    name: deployArguments[0],
    symbol: deployArguments[1],
    decimals: Number(deployArguments[2]),
  };
};

const generateVaultInfo = (
  transactions: any,
  chainId: number,
  address: `0x${string}`,
  deployArguments: string[]
): VaultInfo => {
  const name = deployArguments[1];
  const underlyingAssetAddress = deployArguments[0] as `0x${string}`;
  const underlyingAsset = getUnderlyingAsset(transactions, underlyingAssetAddress);

  return {
    chainId,
    address,
    name,
    decimals: underlyingAsset.decimals,
    symbol: deployArguments[2],
    extensions: {
      underlyingAsset: {
        address: underlyingAssetAddress,
        symbol: underlyingAsset.symbol,
        name: underlyingAsset.name,
      },
    },
  };
};

const formatContract = (
  tokenTransactions: any,
  chainId: number,
  name: string,
  address: `0x${string}`,
  deployArguments: string[]
): Contract => {
  const regex = /V[1-9+]((.{0,2}[0-9+]){0,2})$/g;
  const version = name.match(regex)?.[0]?.slice(1).split(".") || [1, 0, 0];
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
    abi: getAbi(type),
  };

  if (type === "VaultMintRate") {
    return {
      ...defaultContract,
      tokens: [generateVaultInfo(tokenTransactions, chainId, address, deployArguments)],
    };
  } else {
    return defaultContract;
  }
};

export const generateContractList = (deploymentPaths: string[]): ContractList => {
  const contractList: ContractList = {
    name: "Hyperstructure Testnet",
    version: PACKAGE_VERSION,
    timestamp: new Date().toISOString(),
    contracts: [],
  };
  
  // Map to reference deployed contract names by address
  const contractAddressToName = new Map<string, string>();

  const { transactions: stableTokenTransactions } = getBlob(deploymentPaths[0]);
  let { transactions: tokenTransactions } = getBlob(deploymentPaths[1]);

  tokenTransactions = stableTokenTransactions.concat(tokenTransactions);

  deploymentPaths.forEach((deploymentPath) => {
    const deploymentBlob = getBlob(deploymentPath);
    const chainId = deploymentBlob.chain;
    const transactions = deploymentBlob.transactions;

    transactions.forEach(
      ({
        transactionType,
        contractName,
        contractAddress,
        arguments: deployArguments,
        additionalContracts,
      }) => {
        const createdContract = additionalContracts[0];

        // Store name of contract for reference later
        if(contractName) contractAddressToName.set(contractAddress, contractName);

        if (
          transactionType == "CALL" &&
          createdContract &&
          createdContract.transactionType === "CREATE"
        ) {

          // Handle case when contract name isn't available on CALL
          if(!contractName) {
            const storedName = contractAddressToName.get(contractAddress);
            if(storedName) contractName = storedName;
          }

          // Set contract info to the created contract
          transactionType = "CREATE";
          contractAddress = createdContract.address;
          if (contractName === "LiquidationPairFactory") {
            contractName = "LiquidationPair";
          }
        }

        if (transactionType === "CREATE") {
          contractList.contracts.push(
            formatContract(
              tokenTransactions,
              chainId,
              contractName,
              contractAddress,
              deployArguments
            )
          );
        }
      }
    );
  });

  return contractList;
};

export const generateVaultList = (
  vaultDeploymentPath: string,
  tokenDeploymentPaths: string[]
): VaultList => {
  const vaultList: VaultList = {
    name: "PoolTogether Testnet Vault List",
    keywords: ["pooltogether"],
    version: PACKAGE_VERSION,
    timestamp: new Date().toISOString(),
    tokens: [],
  };

  const { transactions: stableTokenTransactions } = getBlob(tokenDeploymentPaths[0]);
  let { transactions: tokenTransactions } = getBlob(tokenDeploymentPaths[1]);

  tokenTransactions = stableTokenTransactions.concat(tokenTransactions);

  const vaultDeploymentBlob = getBlob(vaultDeploymentPath);
  const chainId = vaultDeploymentBlob.chain;
  const vaultTransactions = vaultDeploymentBlob.transactions;

  vaultTransactions.forEach(
    ({ transactionType, contractName, contractAddress, arguments: deployArguments }) => {
      if (transactionType === "CREATE" && contractName === "VaultMintRate") {
        vaultList.tokens.push(
          generateVaultInfo(tokenTransactions, chainId, contractAddress, deployArguments)
        );
      }
    }
  );

  return vaultList;
};

export const writeList = (list: ContractList | VaultList, folderName: string, fileName: string) => {
  const dirpath = `${rootFolder}/${folderName}`;

  fs.mkdirSync(dirpath, { recursive: true });
  fs.writeFile(`${dirpath}/${fileName}.json`, JSON.stringify(list), (err) => {
    if (err) {
      console.error(err);
      return;
    }
  });
};
