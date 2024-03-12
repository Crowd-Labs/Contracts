import '@nomiclabs/hardhat-ethers';
import { expect } from 'chai';
import { ethers } from 'hardhat';
import {
  MockBeCrowdV2BadRevision__factory,
  MockBeCrowdHubV2__factory,
  TransparentUpgradeableProxy__factory,
} from '../../typechain-types';
import { ERRORS } from '../helpers/errors';
import {
  abiCoder,
  deployer,
  beCrowdHub,
  makeSuiteCleanRoom,
  user,
  governance,
  userAddress,
} from '../__setup.spec';

makeSuiteCleanRoom('Upgradeability', function () {
  const valueToSet = 123;

  it('Should fail to initialize an implementation with the same revision', async function () {
    const newImpl = await new MockBeCrowdV2BadRevision__factory(deployer).deploy();
    const proxyHub = TransparentUpgradeableProxy__factory.connect(beCrowdHub.address, deployer);
    const hub = MockBeCrowdV2BadRevision__factory.connect(proxyHub.address, user);
    await expect(proxyHub.upgradeTo(newImpl.address)).to.not.be.reverted;
    await expect(hub.initialize(valueToSet)).to.be.revertedWithCustomError(beCrowdHub, ERRORS.INITIALIZED);
  });

  // The LensHub contract's last storage variable by default is at the 23nd slot (index 22) and contains the emergency admin
  // We're going to validate the first 23 slots and the 24rd slot before and after the change
  it("Should upgrade and set a new variable's value, previous storage is unchanged, new value is accurate", async function () {
    const newImpl = await new MockBeCrowdHubV2__factory(deployer).deploy();
    const proxyHub = TransparentUpgradeableProxy__factory.connect(beCrowdHub.address, deployer);

    const prevStorage: string[] = [];
    for (let i = 0; i < 13; i++) {
      const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
      prevStorage.push(valueAt);
    }

    const prevNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 13);
    const formattedZero = abiCoder.encode(['uint256'], [0]);
    expect(prevNextSlot).to.eq(formattedZero);

    await proxyHub.upgradeTo(newImpl.address);
    await expect(
      MockBeCrowdHubV2__factory.connect(proxyHub.address, user).setAdditionalValue(valueToSet)
    ).to.not.be.reverted;

    for (let i = 0; i < 13; i++) {
      const valueAt = await ethers.provider.getStorageAt(proxyHub.address, i);
      expect(valueAt).to.eq(prevStorage[i]);
    }

    const newNextSlot = await ethers.provider.getStorageAt(proxyHub.address, 13);
    const formattedValue = abiCoder.encode(['uint256'], [valueToSet]);
    expect(newNextSlot).to.eq(formattedValue);
  });
});
