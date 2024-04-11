import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    makeSuiteCleanRoom,
    user,
    userAddress,
    governance,
    beCrowdHub,
    MOCK_URI,
    currency,
    moduleGlobals,
    feeDerivedRule,
    abiCoder,
    tomorrow,
    yestoday,
    treasuryAddress,
    createCollectionFee
} from '../__setup.spec';
import { ZERO_ADDRESS } from '../helpers/constants';
import { ERRORS } from '../helpers/errors';
import { getTimestamp, setNextBlockTimestamp } from '../helpers/utils';
  
makeSuiteCleanRoom('Fee Derived Rule', function () {
    context('Generic', function () {
        beforeEach(async function () {
            await expect(
                beCrowdHub.connect(governance).whitelistDerviedModule([feeDerivedRule.address], true)
            ).to.not.be.reverted;
        });
        context('Negatives', function () {
            it('User should fail to create if the metadata format error...', async function () {
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256'], [1, tomorrow]),
                }, {value: createCollectionFee})).to.be.revertedWithoutReason;
            });
            it('User should fail to create if the data not match.', async function () {
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, tomorrow, 1000000, currency.address, treasuryAddress, false]),
                }, {value: createCollectionFee})).to.be.revertedWithCustomError(feeDerivedRule, ERRORS.INIT_PARAMS_INVALID);
                await expect(
                    moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
                ).to.not.be.reverted;
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, tomorrow, 0, currency.address, treasuryAddress, false]),
                }, {value: createCollectionFee})).to.be.revertedWithCustomError(feeDerivedRule, ERRORS.INIT_PARAMS_INVALID);
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, tomorrow, 100000, currency.address, ZERO_ADDRESS, false]),
                }, {value: createCollectionFee})).to.be.revertedWithCustomError(feeDerivedRule, ERRORS.INIT_PARAMS_INVALID);
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, yestoday, 100000, currency.address, treasuryAddress, false]),
                }, {value: createCollectionFee})).to.be.revertedWithCustomError(feeDerivedRule, ERRORS.INIT_PARAMS_INVALID);
            });
            it('User should fail to create more than mint expired', async function () {
                await expect(
                    moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
                ).to.not.be.reverted;
                const timestamp = parseInt((new Date().getTime() / 1000 ).toFixed(0))
                await expect( beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, timestamp + 100, 100000, currency.address, treasuryAddress, false]),
                }, {value: createCollectionFee})).to.not.be.reverted;

                const currentTimestamp = await getTimestamp();
                await setNextBlockTimestamp(Number(currentTimestamp) + 24 * 60 * 60);

                await expect( beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.revertedWithCustomError(feeDerivedRule, ERRORS.MINT_EXPIRED);
            });
            it('User should fail to create more than mint limit', async function () {
                await expect(
                    moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
                ).to.not.be.reverted;
                await currency.connect(user).mint(userAddress, 1000000000);
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, tomorrow, 100000, currency.address, treasuryAddress, false]),
                }, {value: createCollectionFee})).to.not.be.reverted;
                
                await currency.connect(user).approve(feeDerivedRule.address, 1000000000);
                await expect( beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['address', 'uint256'], [currency.address, 100000]),
                    proof: [],
                })).to.be.not.reverted;
                const balance = await currency.connect(user).balanceOf(userAddress);
                expect(balance).to.equal(1000000000-100000);
                await expect( beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['address', 'uint256'], [currency.address, 100000]),
                    proof: [],
                })).to.be.revertedWithCustomError(feeDerivedRule, ERRORS.MINT_LIMIT_EXCEEDED);
            });
        })

        context('Scenarios', function () {
            it('Should return the expected data when create nft successful', async function () {
                await expect(
                    moduleGlobals.connect(governance).whitelistCurrency(currency.address, true)
                ).to.not.be.reverted;
                await currency.connect(user).mint(userAddress, 1000000000);
                await currency.connect(user).approve(feeDerivedRule.address, 1000000000);
                await expect(beCrowdHub.connect(user).createNewCollection({
                    royalty: 500,
                    collInfoURI: MOCK_URI,
                    collName: "Skull",
                    collSymbol: "Skull",
                    derivedRuleModule: feeDerivedRule.address,
                    derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256','uint256','address', 'address', 'bool'], [1, tomorrow, 100000, currency.address, treasuryAddress, false]),
                }, {value: createCollectionFee})).to.not.be.reverted;
                const limitAmount = await feeDerivedRule.connect(user).getMintLimit(0);
                expect(limitAmount).to.equal(1);
                const alreadyMint = await feeDerivedRule.connect(user).getAlreadyMint(0);
                expect(alreadyMint).to.equal(0);
                await expect( beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['address', 'uint256'], [currency.address, 100000]),
                    proof: [],
                })).to.be.not.reverted;
                const limitAmount1 = await feeDerivedRule.connect(user).getMintLimit(0);
                expect(limitAmount1).to.equal(1);
                const alreadyMint1 = await feeDerivedRule.connect(user).getAlreadyMint(0);
                expect(alreadyMint1).to.equal(1);
                const balance = await currency.connect(user).balanceOf(userAddress);
                expect(balance).to.equal(1000000000-100000);
            });
        })
    })
})