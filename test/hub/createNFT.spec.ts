import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import {
    DerivedNFT,
    DerivedNFT__factory,
} from '../../typechain-types';
import {
    makeSuiteCleanRoom,
    deployer,
    user,
    userAddress,
    userTwo,
    userTwoAddress,
    governance,
    beCrowdHub,
    MOCK_URI,
    freeDerivedRule,
    feeDerivedRule,
    tomorrow,
    abiCoder,
    createCollectionFee,
} from '../__setup.spec';
import { ERRORS } from '../helpers/errors';
import { ethers } from 'hardhat';
  
makeSuiteCleanRoom('Create NFT', function () {
    context('Generic', function () {
        beforeEach(async function () {
            await expect(
                beCrowdHub.connect(governance).whitelistDerviedModule(freeDerivedRule.address, true)
            ).to.not.be.reverted;
            await expect(
                beCrowdHub.connect(governance).whitelistDerviedModule(feeDerivedRule.address, true)
            ).to.not.be.reverted;
            await expect( beCrowdHub.connect(user).createNewCollection({
                royalty: 500,
                collInfoURI: MOCK_URI,
                collName: "Skull",
                collSymbol: "Skull",
                derivedRuleModule: freeDerivedRule.address,
                derivedRuleModuleInitData: abiCoder.encode(['uint256','uint256'], [1000, tomorrow]),
            }, {value: createCollectionFee})).to.not.be.reverted;
        });
        context('Negatives', function () {
            it('User should fail to create a nft with error collectionid', async function () {
                await expect(beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 1,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.COLLECTIONID_NOT_EXIST);
            });
            it('UserTwo should fail to create a nft if collection owner not create 0 nft', async function () {
                await expect(beCrowdHub.connect(userTwo).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.JUST_OWNERCAN_PUBLISH_ROOT_NODE);
            });
            it('User should fail to create a nft if derivedfrom not zero when first add', async function () {
                await expect(beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 1,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.JUST_OWNERCAN_PUBLISH_ROOT_NODE);
            });
            it('user/userTwo should fail to create a nft if derivedfrom error after owner create root node', async function () {
                await expect(beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 0,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.not.reverted;
                await expect(beCrowdHub.connect(userTwo).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 1,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.DERIVEDFROM_NFT_NOT_EXIST);
                await expect(beCrowdHub.connect(user).commitNewNFTIntoCollection({
                    collectionId: 0,
                    nftInfoURI: MOCK_URI,
                    derivedFrom: 2,
                    derivedModuleData: abiCoder.encode(['bool'], [false]),
                    proof: [],
                })).to.be.revertedWithCustomError(beCrowdHub, ERRORS.DERIVEDFROM_NFT_NOT_EXIST);
            });
        })

        context('Scenarios', function () {
            it('User create a nft successful owned by User', async function () {
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

                await deployer.sendTransaction({
                    to: info.derivedNFTAddr,
                    value: ethers.utils.parseEther("1.0"),
                });
                expect(await derivedNft.getLastTokenId()).to.equal(2)
                expect(await derivedNft.totalShares()).to.equal(2)
                expect(await derivedNft.shares(userAddress)).to.equal(1)
                expect(await derivedNft.shares(userTwoAddress)).to.equal(1)
                expect(await derivedNft.creatorAmount()).to.equal(2)

                const before = await ethers.provider.getBalance(userTwoAddress);

                let bal = await derivedNft.releasable(userAddress)
                expect(ethers.utils.formatEther(bal)).to.equal('0.45')
                let bal1 = await derivedNft.releasable(userTwoAddress)
                expect(ethers.utils.formatEther(bal1)).to.equal('0.45')

                await expect(derivedNft.release(userTwoAddress)).to.be.not.reverted;
                const after = await ethers.provider.getBalance(userTwoAddress);
                const subBal = after.sub(before)
                expect(ethers.utils.formatEther(subBal)).to.eq("0.45")
            });
        })
    })
})