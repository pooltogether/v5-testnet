import {
  generateContractList,
  generateVaultList,
  rootFolder,
  writeList,
} from "../helpers/generateContractList";

const stableTokenDeploymentPath = `${rootFolder}/broadcast/DeployStableToken.s.sol/5`;
const tokenDeploymentPath = `${rootFolder}/broadcast/DeployToken.s.sol/5`;
const vaultDeploymentPath = `${rootFolder}/broadcast/DeployVault.s.sol/5`;

const deploymentPaths = [
  stableTokenDeploymentPath,
  tokenDeploymentPath,
  `${rootFolder}/broadcast/DeployPool.s.sol/5`,
  `${rootFolder}/broadcast/DeployYieldVault.s.sol/5`,
  vaultDeploymentPath,
];

const tokenDeploymentPaths = [stableTokenDeploymentPath, tokenDeploymentPath];

writeList(generateContractList(deploymentPaths), "deployments/ethGoerli", "contracts");
writeList(
  generateVaultList(vaultDeploymentPath, tokenDeploymentPaths),
  "deployments/ethGoerli",
  "vaults"
);
