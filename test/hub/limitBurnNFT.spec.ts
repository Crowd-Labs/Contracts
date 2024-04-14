import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    DerivedNFT,
    DerivedNFT__factory,
} from '../../typechain-types';
import {
    makeSuiteCleanRoom,
    user,
    userTwo,
    governance,
    beCrowdHub,
    MOCK_URI,
    freeDerivedRule,
    feeDerivedRule,
    abiCoder,
    tomorrow,
    userAddress,
    userTwoAddress,
    createCollectionFee,
    stakeAndYield,
} from '../__setup.spec';
import helpers from "@nomicfoundation/hardhat-network-helpers";
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';
  
makeSuiteCleanRoom('Limit Burn NFT', function () {
    context('Generic', function () {
        beforeEach(async function () {
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
                derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256'], [1000, tomorrow]),
            }, {value: createCollectionFee})).to.not.be.reverted;
            await expect(beCrowdHub.connect(user).commitNewNFTIntoCollection({
                collectionId: 0,
                nftInfoURI: MOCK_URI,
                derivedFrom: 0,
                derivedModuleData: abiCoder.encode(['bool'], [false]),
                proof: [],
            })).to.be.not.reverted;

            const info = await beCrowdHub.getCollectionInfo(0)
            expect(info.creator).to.eq(userAddress);
            expect(info.derivedRuletModule).to.eq(freeDerivedRule.address);
            let derivedNft: DerivedNFT = DerivedNFT__factory.connect(info.derivedNFTAddr, user)
            expect(await derivedNft.getLastTokenId()).to.equal(1)
            expect(await derivedNft.balanceOf(userAddress)).to.equal(1)

            await expect(beCrowdHub.connect(userTwo).commitNewNFTIntoCollection({
                collectionId: 0,
                nftInfoURI: MOCK_URI,
                derivedFrom: 0,
                derivedModuleData: abiCoder.encode(['bool'], [false]),
                proof: [],
            })).to.be.not.reverted;
        });
        context('Negatives', async function () {
            it('UserTwo can not burn the nft not owned', async function () {
                await expect(beCrowdHub.connect(userTwo).limitBurnTokenByCollectionOwner({
                    collectionId: 0,
                    tokenId: 0,
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_COLLECTION_OWNER);
            });

            it('Can not claim ETH back before time deadline', async function () {
                await expect(stakeAndYield.connect(user).claimStakeEth(0)).to.be.revertedWithCustomError(stakeAndYield, ERRORS.Not_ARRIVE_CLAIM_TIME);
            });

            it('Can not claim ETH back if not collection owner', async function () {
                await expect(stakeAndYield.connect(userTwo).claimStakeEth(0)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_COLLECTION_OWNER);
            });

            it('User can not delete zero nft', async function () {
                await expect(beCrowdHub.connect(user).limitBurnTokenByCollectionOwner({
                    collectionId: 0,
                    tokenId: 0,
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.CAN_NOT_DELETE_ZERO_NFT);
            });

            it('Can not claim ETH back if not collection owner even time arrive', async function () {
                await ethers.provider.send("evm_increaseTime", [8 * 24 * 3600]);
                await expect(stakeAndYield.connect(userTwo).claimStakeEth(0)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.NOT_COLLECTION_OWNER);
            });

            it('User can not burn the nft cause time exceed', async function () {
                await ethers.provider.send("evm_increaseTime", [8 * 24 * 3600]);
                await expect(beCrowdHub.connect(user).limitBurnTokenByCollectionOwner({
                    collectionId: 0,
                    tokenId: 1,
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.BURN_EXPIRE_ONE_WEEK);
            });
        })
        context('Scenarios', async function () {
            it('User can burn the nft sucess in time', async function () {
                await expect(beCrowdHub.connect(user).limitBurnTokenByCollectionOwner({
                    collectionId: 0,
                    tokenId: 0,
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.CAN_NOT_DELETE_ZERO_NFT);

                await expect(beCrowdHub.connect(user).limitBurnTokenByCollectionOwner({
                    collectionId: 0,
                    tokenId: 1,
                })).to.be.not.reverted;

                const info = await beCrowdHub.getCollectionInfo(0)
                expect(info.creator).to.eq(userAddress);
                expect(info.derivedRuletModule).to.eq(freeDerivedRule.address);
                let derivedNft: DerivedNFT = DerivedNFT__factory.connect(info.derivedNFTAddr, user)
                expect(await derivedNft.getLastTokenId()).to.equal(2)
                expect(await derivedNft.balanceOf(userTwoAddress)).to.equal(0)
            });

            it('Claim ETH back if claim time arrive', async function () {
                await ethers.provider.send("evm_increaseTime", [8 * 24 * 3600]);
                const before = await ethers.provider.getBalance(userAddress);
                await expect(stakeAndYield.connect(user).claimStakeEth(0)).to.be.not.reverted;
                const after = await ethers.provider.getBalance(userAddress);
                const subBal = after.sub(before)
                expect(subBal).to.lt(ethers.utils.parseEther("0.05"));
                expect(subBal).to.gt(ethers.utils.parseEther("0.045"));
            });
        })
    })
})