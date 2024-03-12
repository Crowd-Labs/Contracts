import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {ethers} from "hardhat"
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    userTwo,
    governance,
    beCrowdHub,
    MOCK_URI,
    freeDerivedRule,
    feeDerivedRule,
    stakeAndYield,
    yestoday,
    tomorrow,
    abiCoder,
    derivedNFTImpl,
} from '../__setup.spec';
import {createCollectionReturningCollId, BeCrowdState} from '../helpers/utils'
import { ERRORS } from '../helpers/errors';
  
makeSuiteCleanRoom('Create Collection', function () {
    context('Generic', function () {
        context('Negatives', function () {
            it('User should fail to create a collection when not send create collection fee', async function () {
                await expect(beCrowdHub.connect(governance).setStakeEthAmountForInitialCollection(1000)).to.not.be.reverted;
                await expect(beCrowdHub.connect(governance).setStakeAndYieldContractAddress(stakeAndYield.address)).to.not.be.reverted;
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: freeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','bool'], [1000, tomorrow, false]),
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_ENOUGH_FUNDS);
            });
            it('User should fail to create collection with an unwhitelisted free derived rule', async function () {
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: freeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','bool'], [1000, tomorrow, false]),
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.DERIVED_RULEMODULE_NOT_WHITELISTED);
            });
            it('User should fail to create collection with an unwhitelisted fee derived rule', async function () {
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','bool'], [1000, tomorrow, false]),
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.DERIVED_RULEMODULE_NOT_WHITELISTED);
            });
            it('User should fail to create collection with an too high royalty', async function () {
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 1500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','bool'], [1000, tomorrow, false]),
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.ROYALTY_TOO_HIGH);
            });
            it('User should fail to create collection with invalid derived data format', async function () {
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([freeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([feeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: freeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: [0x12, 0x34],
                })).to.be.revertedWithoutReason;
            });
            it('User should fail to create collection with endtime less than now', async function () {
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([freeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([feeDerivedRule.address], true)
                ).to.not.be.reverted;

                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: freeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','bool'], [1000, yestoday, false]),
                })).to.be.revertedWithCustomError(freeDerivedRule, ERRORS.INIT_PARAMS_INVALID);
            });
        })

        context('Scenarios', function () {
            it('Should return the expected token IDs when create collection', async function () {
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([freeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([feeDerivedRule.address], true)
                ).to.not.be.reverted;
                expect(
                    await createCollectionReturningCollId({
                      vars: {
                        royalty: 500,
                        collInfoURI: MOCK_URI,
                        collName: "Skull",
                        collSymbol: "Skull",
                        derivedRuleModule: freeDerivedRule.address,
                        nftModule: derivedNFTImpl.address,
                        derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256'], [1000, tomorrow]),
                      },
                    })
                  ).to.eq(0);
                expect(
                    await createCollectionReturningCollId({
                        sender: userTwo,
                        vars: {
                            royalty: 500,
                            collInfoURI: MOCK_URI,
                            collName: "Skull",
                            collSymbol: "Skull",
                            derivedRuleModule: freeDerivedRule.address,
                            nftModule: derivedNFTImpl.address,
                            derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256'], [1000, tomorrow]),
                        },
                    })
                ).to.eq(1);
            });
            it('User should create a collection,fetched post data should be accurate', async function () {
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([freeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([feeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: freeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','bool'], [1000, tomorrow, false]),
                })).to.not.be.reverted;

                const info = await beCrowdHub.getCollectionInfo(0)
                expect(info.creator).to.eq(userAddress);
                expect(info.derivedRuletModule).to.eq(freeDerivedRule.address);
            });

            it('user should create success when pass fee', async function () {
                await expect(
                    beCrowdHub.connect(governance).whitelistDerviedModule([freeDerivedRule.address], true)
                ).to.not.be.reverted;
                await expect(beCrowdHub.connect(governance).setState(BeCrowdState.OpenForAll)).to.not.be.reverted;

                await expect(beCrowdHub.connect(governance).setStakeEthAmountForInitialCollection(1000)).to.not.be.reverted;
                await expect(beCrowdHub.connect(governance).setStakeAndYieldContractAddress(stakeAndYield.address)).to.not.be.reverted;
                
                const before = await ethers.provider.getBalance(stakeAndYield.address);
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: freeDerivedRule.address,
                    nftModule: derivedNFTImpl.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256'], [1000, tomorrow]),
                },
                {value: 1000}
                )).to.not.be.reverted;
                const after = await ethers.provider.getBalance(stakeAndYield.address);
                expect(after.sub(before)).to.eq("1000")
                
                const info = await beCrowdHub.getCollectionInfo(0)
                expect(info.creator).to.eq(userAddress);
                expect(info.derivedRuletModule).to.eq(freeDerivedRule.address);
            });
        })
    })
})