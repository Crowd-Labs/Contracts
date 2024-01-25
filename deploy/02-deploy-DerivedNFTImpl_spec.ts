/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { hexlify, keccak256, RLP } from 'ethers/lib/utils'
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {

  const ethers = hre.ethers;
  const { deployer } = await hre.getNamedAccounts()
  let deployerNonce = await ethers.provider.getTransactionCount(deployer);
  const BeCrowdHubProxyNonce = hexlify(deployerNonce + 1);
  const BeCrowdHubProxyAddress =
        '0x' + keccak256(RLP.encode([deployer, BeCrowdHubProxyNonce])).substr(26);
  const StakeAndYieldNonce = hexlify(deployerNonce + 2);
  const StakeAndYieldAddress =
              '0x' + keccak256(RLP.encode([deployer, StakeAndYieldNonce])).substr(26);
        
  await deployAndVerifyAndThen({
      hre,
      name: "DerivedNFTImpl",
      contract: 'DerivedNFT',
      args: [BeCrowdHubProxyAddress, StakeAndYieldAddress],
    })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['DerivedNFTImpl']

export default deployFn
