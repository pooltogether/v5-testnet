import {
  generateContractList,
  generateVaultList,
  writeList,
} from "../helpers/generateContractList";

const stableTokenDeploymentPath = `${__dirname}/../../broadcast/DeployStableToken.s.sol/31337`;
const tokenDeploymentPath = `${__dirname}/../../broadcast/DeployToken.s.sol/31337`;
const vaultDeploymentPath = `${__dirname}/../../broadcast/DeployVault.s.sol/31337`;

const deploymentPaths = [
  stableTokenDeploymentPath,
  tokenDeploymentPath,
  `${__dirname}/../../broadcast/DeployPool.s.sol/31337`,
  `${__dirname}/../../broadcast/DeployYieldVault.s.sol/31337`,
  vaultDeploymentPath,
];

const tokenDeploymentPaths = [stableTokenDeploymentPath, tokenDeploymentPath];

writeList(generateContractList(deploymentPaths), "deployments/local", "contracts");
writeList(
  generateVaultList(vaultDeploymentPath, tokenDeploymentPaths),
  "deployments/local",
  "vaults"
);
