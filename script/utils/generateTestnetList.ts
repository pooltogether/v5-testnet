import { generateContractList, generateVaultList, writeList } from '../helpers/generateContractList';

const ethereumGoerliDeployments = `${__dirname}/../../broadcast/Deploy.s.sol/5`;

const deploymentPaths = [
  ethereumGoerliDeployments
];

writeList(generateContractList(deploymentPaths), 'deployments/ethGoerli', 'contracts');
writeList(generateVaultList(deploymentPaths), 'deployments/ethGoerli', 'vaults');
