/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import { hexlify, keccak256, RLP } from 'ethers/lib/utils';
import {
  deployAndVerifyAndThen,
} from '../scripts/deploy-utils'

const deployFn: DeployFunction = async (hre) => {
    
    const ethers = hre.ethers;
    const { deployer } = await hre.getNamedAccounts()
    let deployerNonce = await ethers.provider.getTransactionCount(deployer);
    const derivedNFTNonce = hexlify(deployerNonce + 1);
    const derivedNFTImplAddress =
        '0x' + keccak256(RLP.encode([deployer, derivedNFTNonce])).substr(26);

    await deployAndVerifyAndThen({
        hre,
        name: "BeCrowdHubImpl",
        contract: 'BeCrowdHub',
        args: [derivedNFTImplAddress],
      })
}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['BeCrowdHubImpl']

export default deployFn
