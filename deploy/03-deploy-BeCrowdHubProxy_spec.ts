/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  getContractFromArtifact,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const BeCrowdHubImpl = await getContractFromArtifact(
    hre,
    "BeCrowdHubImpl"
  )
  const { deployer,  governance} = await hre.getNamedAccounts()

  let data = BeCrowdHubImpl.interface.encodeFunctionData('initialize', [
    governance
  ]);

  await deployAndVerifyAndThen({
    hre,
    name: "BeCrowdHubProxy",
    contract: 'TransparentUpgradeableProxy',
    args: [BeCrowdHubImpl.address, deployer, data],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['BeCrowdHubProxy']

export default deployFn
