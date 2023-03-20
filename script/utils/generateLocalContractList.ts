import { generateContractList, writeContractList } from '../helpers/generateContractList';

const localDeployments = `${__dirname}/../../broadcast/Deploy.s.sol/31337`;

const deploymentPaths = [
  localDeployments
];

writeContractList(generateContractList(deploymentPaths), 'local-contracts');
