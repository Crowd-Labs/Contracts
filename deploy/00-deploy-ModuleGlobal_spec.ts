/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
  const { deployer,  governance} = await hre.getNamedAccounts()

  await deployAndVerifyAndThen({
    hre,
    name: "ModuleGlobals",
    contract: 'ModuleGlobals',
    args: [governance, governance, 1000],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['ModuleGlobals']

export default deployFn
