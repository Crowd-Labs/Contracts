/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {

  await deployAndVerifyAndThen({
    hre,
    name: "Lock",
    contract: 'Lock',
    args: [1737295644],
  })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['Lock']

export default deployFn
