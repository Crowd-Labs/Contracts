/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  getContractFromArtifact,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {

  const BeCrowdHubProxy = await getContractFromArtifact(
    hre,
    "BeCrowdHubProxy"
  )

  await deployAndVerifyAndThen({
      hre,
      name: "FreeDerivedRule",
      contract: 'FreeDerivedRule',
      args: [BeCrowdHubProxy.address],
    })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['FreeDerivedRule']

export default deployFn
