import { generateContractList, generateVaultList, writeList } from '../helpers/generateContractList';

const localDeployments = `${__dirname}/../../broadcast/Deploy.s.sol/31337`;

const deploymentPaths = [
  localDeployments
];

writeList(generateContractList(deploymentPaths), 'deployments/local', 'contracts');
writeList(generateVaultList(deploymentPaths), 'deployments/local', 'vaults');
