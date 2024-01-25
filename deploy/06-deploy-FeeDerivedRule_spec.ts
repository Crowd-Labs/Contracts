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

  const ModuleGlobals = await getContractFromArtifact(
    hre,
    "ModuleGlobals"
  )

  await deployAndVerifyAndThen({
      hre,
      name: "FeeDerivedRule",
      contract: 'FeeDerivedRule',
      args: [BeCrowdHubProxy.address, ModuleGlobals.address],
    })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['FeeDerivedRule']

export default deployFn
