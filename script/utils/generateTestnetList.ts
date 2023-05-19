import {
  generateContractList,
  generateVaultList,
  rootFolder,
  writeList,
} from "../helpers/generateContractList";

const ethGoerliStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/5`;
const ethGoerliTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/5`;
const ethGoerliVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/5`;

const ethGoerliDeploymentPaths = [
  ethGoerliStableTokenDeploymentPath,
  ethGoerliTokenDeploymentPath,
  `${rootFolder}/broadcast/DeployPool.s.sol/5`,
  `${rootFolder}/broadcast/DeployYieldVault.s.sol/5`,
  ethGoerliVaultDeploymentPath,
];

const ethGoerliTokenDeploymentPaths = [ethGoerliStableTokenDeploymentPath, ethGoerliTokenDeploymentPath];

writeList(generateContractList(ethGoerliDeploymentPaths), "deployments/ethGoerli", "contracts");
writeList(
  generateVaultList(ethGoerliVaultDeploymentPath, ethGoerliTokenDeploymentPaths),
  "deployments/ethGoerli",
  "vaults"
);

const ethSepoliaStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/11155111`;
const ethSepoliaTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/11155111`;
const ethSepoliaVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/11155111`;

const ethSepoliaDeploymentPaths = [
  ethSepoliaStableTokenDeploymentPath,
  ethSepoliaTokenDeploymentPath,
  `${rootFolder}/broadcast/DeployPool.s.sol/11155111`,
  `${rootFolder}/broadcast/DeployYieldVault.s.sol/11155111`,
  ethSepoliaVaultDeploymentPath,
];

const ethSepoliaTokenDeploymentPaths = [ethSepoliaStableTokenDeploymentPath, ethSepoliaTokenDeploymentPath];

writeList(generateContractList(ethSepoliaDeploymentPaths), "deployments/ethSepolia", "contracts");
writeList(
  generateVaultList(ethSepoliaVaultDeploymentPath, ethSepoliaTokenDeploymentPaths),
  "deployments/ethSepolia",
  "vaults"
);

const mumbaiStableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/80001`;
const mumbaiTokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/80001`;
const mumbaiVaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/80001`;

const mumbaiDeploymentPaths = [
  mumbaiStableTokenDeploymentPath,
  mumbaiTokenDeploymentPath,
  `${rootFolder}/broadcast/DeployPool.s.sol/80001`,
  `${rootFolder}/broadcast/DeployYieldVault.s.sol/80001`,
  mumbaiVaultDeploymentPath,
];

const mumbaiTokenDeploymentPaths = [mumbaiStableTokenDeploymentPath, mumbaiTokenDeploymentPath];

writeList(generateContractList(mumbaiDeploymentPaths), "deployments/mumbai", "contracts");
writeList(
  generateVaultList(mumbaiVaultDeploymentPath, mumbaiTokenDeploymentPaths),
  "deployments/mumbai",
  "vaults"
);
