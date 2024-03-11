
import '@nomiclabs/hardhat-ethers';
import { expect, use } from 'chai';
import { BytesLike, Signer, Wallet } from 'ethers';
import { ethers } from 'hardhat';
import {
  ModuleGlobals,
  ModuleGlobals__factory,
  DerivedNFT,
  DerivedNFT__factory,
  BeCrowdHub,
  BeCrowdHub__factory,
  FreeDerivedRule,
  FreeDerivedRule__factory,
  TransparentUpgradeableProxy__factory,
  FeeDerivedRule,
  FeeDerivedRule__factory,
  Currency,
  Currency__factory,
  Events,
  Events__factory,
  StakeAndYield__factory,
  StakeAndYield,
} from '../typechain-types';
import {
  computeContractAddress,
  BeCrowdState,
  revertToSnapshot,
  takeSnapshot,
} from './helpers/utils';
import hre from 'hardhat'
import { ERRORS } from './helpers/errors';
import { FAKE_PRIVATEKEY, ZERO_ADDRESS } from './helpers/constants';

export const BPS_MAX = 10000;
export const TREASURY_FEE_BPS = 50;
export const REFERRAL_FEE_BPS = 250;
export const ROYALTY = 1000;
export const MOCK_URI = 'https://ipfs.io/ipfs/QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR';
export const OTHER_MOCK_URI = 'https://ipfs.io/ipfs/QmSfyMcnh1wnJHrAWCBjZHapTS859oNSsuDFiAPPdAHgHP';
export let accounts: Signer[];
export let deployer: Signer;
export let user: Signer;
export let userTwo: Signer;
export let userThree: Signer;
export let governance: Signer;
export let treasury: Signer;
export let admin: Signer;
export let deployerAddress: string;
export let userAddress: string;
export let userTwoAddress: string;
export let userThreeAddress: string;
export let governanceAddress: string;
export let treasuryAddress: string;
export let adminAddress: string;
export let testWallet: Wallet;
export let moduleGlobals: ModuleGlobals;
export let derivedNFTImpl: DerivedNFT;
export let beCrowdHubImpl: BeCrowdHub;
export let beCrowdHub: BeCrowdHub;
export let currency: Currency;
export let stakeAndYield: StakeAndYield
export let freeDerivedRule: FreeDerivedRule;
export let feeDerivedRule: FeeDerivedRule;
export let eventsLib: Events;
export let abiCoder = hre.ethers.utils.defaultAbiCoder;
export let yestoday = parseInt((new Date().getTime() / 1000 ).toFixed(0)) - 24 * 3600
export let now = parseInt((new Date().getTime() / 1000 ).toFixed(0))
export let tomorrow = parseInt((new Date().getTime() / 1000 ).toFixed(0)) + 24 * 3600

export function sleep (time: number | undefined) {
  return new Promise((resolve) => setTimeout(resolve, time));
}

export function makeSuiteCleanRoom(name: string, tests: () => void) {
  describe(name, () => {
    beforeEach(async function () {
      await takeSnapshot();
    });
    tests();
    afterEach(async function () {
      await revertToSnapshot();
    });
  });
}

before(async function () {
  abiCoder = ethers.utils.defaultAbiCoder;
  testWallet = new ethers.Wallet(FAKE_PRIVATEKEY).connect(ethers.provider);
  accounts = await ethers.getSigners();
  deployer = accounts[0];
  user = accounts[1];
  userTwo = accounts[2];
  userThree = accounts[3];
  governance = accounts[4];
  treasury = accounts[5];
  admin = accounts[6];

  deployerAddress = await deployer.getAddress();
  userAddress = await user.getAddress();
  userTwoAddress = await userTwo.getAddress();
  userThreeAddress = await userThree.getAddress();
  governanceAddress = await governance.getAddress();
  treasuryAddress = await treasury.getAddress();
  adminAddress = await admin.getAddress();

  moduleGlobals = await new ModuleGlobals__factory(deployer).deploy(
    governanceAddress,
    treasuryAddress,
    TREASURY_FEE_BPS
  );
  
  //mockLensHub = await new MockLensHub__factory(deployer).deploy();
  // Here, we pre-compute the nonces and addresses used to deploy the contracts.
  const nonce = await deployer.getTransactionCount();
  // nonce + 0 is dervied NFT impl
  // nonce + 1 is impl
  // nonce + 2 is hub proxy

  const hubProxyAddress = computeContractAddress(deployerAddress, nonce + 2); //'0x' + keccak256(RLP.encode([deployerAddress, hubProxyNonce])).substr(26);
  const stakeAndYieldAndAddress = computeContractAddress(deployerAddress, nonce + 3);

  derivedNFTImpl = await new DerivedNFT__factory(deployer).deploy(hubProxyAddress, stakeAndYieldAndAddress);
  beCrowdHubImpl = await new BeCrowdHub__factory(deployer).deploy(
    moduleGlobals.address
  );

  let data = beCrowdHubImpl.interface.encodeFunctionData('initialize', [
    governanceAddress,
  ]);
  let proxy = await new TransparentUpgradeableProxy__factory(deployer).deploy(
    beCrowdHubImpl.address,
    deployerAddress,
    data
  );
  
  // Connect the hub proxy to the LensHub factory and the user for ease of use.
  beCrowdHub = BeCrowdHub__factory.connect(proxy.address, user);

  // StakeAndYield
  stakeAndYield = await new StakeAndYield__factory(deployer).deploy(proxy.address);

  // Currency
  currency = await new Currency__factory(deployer).deploy();

  // Modules
  freeDerivedRule = await new FreeDerivedRule__factory(deployer).deploy(beCrowdHub.address);
  feeDerivedRule = await new FeeDerivedRule__factory(deployer).deploy(beCrowdHub.address, moduleGlobals.address);

  await expect(beCrowdHub.connect(governance).whitelistNftModule(derivedNFTImpl.address, true)).to.not.be.reverted;

  await expect(beCrowdHub.connect(governance).setEmergencyAdmin(adminAddress)).to.not.be.reverted;
  await expect(beCrowdHub.connect(admin).setState(BeCrowdState.CreateCollectionPaused)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.EMERGENCYADMIN_JUST_CAN_PAUSE);

  await expect(beCrowdHub.connect(governance).setState(BeCrowdState.CreateCollectionPaused)).to.not.be.reverted;
  await expect(beCrowdHub.connect(governance).setMaxRoyalty(1000)).to.not.be.reverted;
  await expect(beCrowdHub.connect(governance).setHubRoyalty(treasuryAddress, 1000)).to.not.be.reverted;

  await expect(beCrowdHub.connect(user).setMaxRoyalty(1000)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_GOVERNANCE);
  await expect(beCrowdHub.connect(user).setState(BeCrowdState.CreateCollectionPaused)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_GOVERNANCE_OR_EMERGENCYADMIN);
  await expect(beCrowdHub.connect(user).setHubRoyalty(treasuryAddress, 1000)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_GOVERNANCE);
  await expect(beCrowdHub.connect(user).setEmergencyAdmin(adminAddress)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_GOVERNANCE);
  await expect(beCrowdHub.connect(user).setStakeEthAmountForInitialCollection(1000)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_GOVERNANCE);
  await expect(beCrowdHub.connect(user).setStakeAndYieldContractAddress(adminAddress)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_GOVERNANCE);

  expect(beCrowdHub).to.not.be.undefined;
  expect(stakeAndYield).to.not.be.undefined;
  expect(currency).to.not.be.undefined;

  // Event library deployment is only needed for testing and is not reproduced in the live environment
  eventsLib = await new Events__factory(deployer).deploy();
});
