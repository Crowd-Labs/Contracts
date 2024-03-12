/* Imports: Internal */
import { DeployFunction } from 'hardhat-deploy/dist/types'
import {
  getContractFromArtifact,
  isHardhatNode,
} from '../scripts/deploy-utils'
import { ethers } from 'hardhat'
import fs from 'fs';

const deployFn: DeployFunction = async (hre) => {

  const {governance, treasury} = await hre.getNamedAccounts()
  console.log("gov addr: ", governance)

  const FreeDerivedRule = await getContractFromArtifact(
    hre,
    "FreeDerivedRule"
  )

  const FeeDerivedRule = await getContractFromArtifact(
    hre,
    "FeeDerivedRule"
  )

  const WhitelistFreeDerivedRule = await getContractFromArtifact(
    hre,
    "WhitelistFreeDerivedRule"
  )

  const WhitelistFeeDerivedRule = await getContractFromArtifact(
    hre,
    "WhitelistFeeDerivedRule"
  )

  const BeCrowdHubProxy = await getContractFromArtifact(
    hre,
    "BeCrowdHubProxy",
    {
      iface: 'BeCrowdHub',
      signerOrProvider: governance,
    }
  )

  const StakeAndYield = await getContractFromArtifact(
    hre,
    "StakeAndYield"
  )

  const ModuleGlobals = await getContractFromArtifact(
    hre,
    "ModuleGlobals",
    {
      signerOrProvider: governance,
    }
  )

  const BeCrowdHubImpl = await getContractFromArtifact(
    hre,
    "BeCrowdHubImpl"
  )
  const DerivedNFTImpl = await getContractFromArtifact(
    hre,
    "DerivedNFTImpl"
  )

  const array = [FreeDerivedRule.address, FeeDerivedRule.address, WhitelistFreeDerivedRule.address, WhitelistFeeDerivedRule.address];
  
  console.log("start set whitelist...")
  await BeCrowdHubProxy.whitelistDerviedModule(array, true);
  await BeCrowdHubProxy.whitelistNftModule([DerivedNFTImpl.address], true);

  console.log("start set param...")
  console.log("maxRoyalty: ", await BeCrowdHubProxy._maxRoyalty())
  console.log("state: ", await BeCrowdHubProxy._state())
  console.log("_royaltyAddress: ", await BeCrowdHubProxy._royaltyAddress())
  console.log("_royaltyPercentage: ", await BeCrowdHubProxy._royaltyPercentage())
  console.log("_stakeEthAmountForInitialCollection: ", await BeCrowdHubProxy._stakeEthAmountForInitialCollection())
  console.log("_stakeAndYieldContractAddress: ", await BeCrowdHubProxy._stakeAndYieldContractAddress());


  const ETH_ADDRESS = '0x0000000000000000000000000000000000000001';
  const USDB_ADDRESS = '0x4300000000000000000000000000000000000003';
  const WETH_ADDRESS = '0x4300000000000000000000000000000000000004';
  console.log("ETH: ", await ModuleGlobals.isCurrencyWhitelisted(ETH_ADDRESS))
  console.log("USDB: ", await ModuleGlobals.isCurrencyWhitelisted(USDB_ADDRESS))
  console.log("WETH: ", await ModuleGlobals.isCurrencyWhitelisted(WETH_ADDRESS))

  const addrs = {
    'ChainId: ': hre.network.config.chainId,
    'Timestamp: ': new Date(),
    'BeCrowdHubProxy: ': BeCrowdHubProxy.address,
    'BeCrowdHubImpl: ': BeCrowdHubImpl.address,
    'DerivedNFTImpl: ': DerivedNFTImpl.address,
    'ModuleGlobals: ': ModuleGlobals.address,
    'StakeAndYield ': StakeAndYield.address,
    'FreeDerivedRule: ': FreeDerivedRule.address,
    'FeeDerivedRule: ': FeeDerivedRule.address,
    'WhitelistFreeDerivedRule: ': WhitelistFreeDerivedRule.address,
    'WhitelistFeeDerivedRule': WhitelistFeeDerivedRule.address,
  };
  let old_data: any = fs.readFileSync('addresses.json')
  if(old_data.length == 0)
  {
      fs.writeFileSync('addresses.json', JSON.stringify(addrs, null, 2))
      return
  }else{
    let json_obj: any = [JSON.parse(old_data)] // without brackets it reverts an error
    json_obj.push(addrs)
    fs.writeFileSync('addresses.json', JSON.stringify(json_obj, null, 2))
  }

}

// This is kept during an upgrade. So no upgrade tag.
deployFn.tags = ['preEnv']

export default deployFn
