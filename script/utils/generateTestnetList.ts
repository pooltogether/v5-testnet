import {
  generateContractList,
  generateVaultList,
  writeList,
} from "../helpers/generateContractList";

const stableTokenDeploymentPath = `${__dirname}/../../broadcast/DeployStableToken.s.sol/5`;
const tokenDeploymentPath = `${__dirname}/../../broadcast/DeployToken.s.sol/5`;
const vaultDeploymentPath = `${__dirname}/../../broadcast/DeployVault.s.sol/5`;

const deploymentPaths = [
  stableTokenDeploymentPath,
  tokenDeploymentPath,
  `${__dirname}/../../broadcast/DeployPool.s.sol/5`,
  `${__dirname}/../../broadcast/DeployYieldVault.s.sol/5`,
  vaultDeploymentPath,
];

const tokenDeploymentPaths = [stableTokenDeploymentPath, tokenDeploymentPath];

writeList(generateContractList(deploymentPaths), "deployments/ethGoerli", "contracts");
writeList(
  generateVaultList(vaultDeploymentPath, tokenDeploymentPaths),
  "deployments/ethGoerli",
  "vaults"
);
