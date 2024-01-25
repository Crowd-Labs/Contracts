/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  isHardhatNode,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {

  if((await isHardhatNode(hre)))
  {
    await deployAndVerifyAndThen({
      hre,
      name: "Currency",
      contract: 'Currency',
      args: [],
    })
  } 
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['Currency']

export default deployFn
