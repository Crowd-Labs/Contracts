/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  deployAndVerifyAndThen,
  getContractFromArtifact,
} from '../scripts/deploy-utils'
import { hexlify, keccak256, RLP } from 'ethers/lib/utils'

const deployFn: DeployFunction = async (hre) => {
  const BeCrowdHubImpl = await getContractFromArtifact(
    hre,
    "BeCrowdHubImpl"
  )
  const { deployer,  governance} = await hre.getNamedAccounts()

  const ethers = hre.ethers;
  let deployerNonce = await ethers.provider.getTransactionCount(deployer);
  const StakeAndYieldNonce = hexlify(deployerNonce + 1);
  const StakeAndYieldAddress =
              '0x' + keccak256(RLP.encode([deployer, StakeAndYieldNonce])).substr(26);

  let data = BeCrowdHubImpl.interface.encodeFunctionData('initialize', [
    governance, StakeAndYieldAddress
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
