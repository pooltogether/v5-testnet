import { generateContractList, writeContractList } from '../helpers/generateContractList';

const ethereumGoerliDeployments = `${__dirname}/../../broadcast/Deploy.s.sol/5`;

const deploymentPaths = [
  ethereumGoerliDeployments
];

writeContractList(generateContractList(deploymentPaths), 'testnet-contracts');
