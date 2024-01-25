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
  
  console.log("start set whitelist...")
  await BeCrowdHubProxy.whitelistDerviedModule(FreeDerivedRule.address, true);
  await BeCrowdHubProxy.whitelistDerviedModule(FeeDerivedRule.address, true);
  await BeCrowdHubProxy.whitelistDerviedModule(WhitelistFreeDerivedRule.address, true);
  await BeCrowdHubProxy.whitelistDerviedModule(WhitelistFeeDerivedRule.address, true);

  const MAX_ROYALTY = 1000;
  const ROYALTY_PERCENTAGE = 1000;
  console.log("start set param...")
  await BeCrowdHubProxy.setMaxRoyalty(MAX_ROYALTY);
  await BeCrowdHubProxy.setHubRoyalty(treasury, ROYALTY_PERCENTAGE);
  await BeCrowdHubProxy.setState(0);
  await BeCrowdHubProxy.setStakeEthAmountForInitialCollection(ethers.utils.parseEther("0.01"));
  await BeCrowdHubProxy.setStakeAndYieldContractAddress(StakeAndYield.address);

  const ETH_ADDRESS = '0x0000000000000000000000000000000000000001';
  await ModuleGlobals.whitelistCurrency(ETH_ADDRESS,true);
  if((await isHardhatNode(hre))){
    const Currency = await getContractFromArtifact(
      hre,
      "Currency"
    )
    await ModuleGlobals.whitelistCurrency(Currency.address,true);
  }else{
    await ModuleGlobals.whitelistCurrency("0x4200000000000000000000000000000000000022",true);
    await ModuleGlobals.whitelistCurrency("0x4200000000000000000000000000000000000023",true);
  }

  const BeCrowdHubImpl = await getContractFromArtifact(
    hre,
    "BeCrowdHubImpl"
  )
  const addrs = {
    'ChainId: ': hre.network.config.chainId,
    'Timestamp: ': new Date(),
    'BeCrowdHubProxy: ': BeCrowdHubProxy.address,
    'BeCrowdHubImpl: ': BeCrowdHubImpl.address,
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
