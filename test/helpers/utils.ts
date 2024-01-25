import '@nomiclabs/hardhat-ethers';
import { BigNumberish, Bytes, logger, utils, BigNumber, Contract, Signer } from 'ethers';
import {
  testWallet,
  user,
  aiCooHub,
} from '../__setup.spec';
import { expect } from 'chai';
import { HARDHAT_CHAINID, MAX_UINT256 } from './constants';
import { BytesLike, hexlify, keccak256, RLP, toUtf8Bytes } from 'ethers/lib/utils';
import { TransactionReceipt, TransactionResponse } from '@ethersproject/providers';
import hre, { ethers } from 'hardhat';
import { readFileSync } from 'fs';
import { join } from 'path';
import { AiCooDataTypes } from '../../typechain-types/contracts/core/DerivedNFT';

export enum AiCooState {
  OpenForAll,
  CreateCollectionPaused,
  Paused
}

export interface CreateReturningTokenIdStruct {
  sender?: Signer;
  vars: AiCooDataTypes.CreateNewCollectionDataStruct
}

export interface CreateWithSigReturningTokenIdStruct {
  sender?: Signer;
  vars: AiCooDataTypes.CreateNewCollectionDataStruct;
  sig: AiCooDataTypes.EIP712SignatureStruct;
}

export async function createCollectionReturningCollId({
  sender = user,
  vars
}: CreateReturningTokenIdStruct): Promise<BigNumber> {
  let tokenId = await aiCooHub.connect(sender).callStatic.createNewCollection(vars);
  await expect(aiCooHub.connect(sender).createNewCollection(vars)).to.not.be.reverted;
  return tokenId;
}

export function computeContractAddress(deployerAddress: string, nonce: number): string {
  const hexNonce = hexlify(nonce);
  return '0x' + keccak256(RLP.encode([deployerAddress, hexNonce])).substr(26);
}

export function getChainId(): number {
  return hre.network.config.chainId || HARDHAT_CHAINID;
}

export function getAbbreviation(handle: string) {
  let slice = handle.substr(0, 4);
  if (slice.charAt(3) == ' ') {
    slice = slice.substr(0, 3);
  }
  return slice;
}

export async function waitForTx(
  tx: Promise<TransactionResponse> | TransactionResponse,
  skipCheck = false
): Promise<TransactionReceipt> {
  if (!skipCheck) await expect(tx).to.not.be.reverted;
  return await (await tx).wait();
}

export async function resetFork(): Promise<void> {
  await hre.network.provider.request({
    method: 'hardhat_reset',
    params: [
      {
        forking: {
          jsonRpcUrl: process.env.MAINNET_RPC_URL,
          blockNumber: 12012081,
        },
      },
    ],
  });
  console.log('\t> Fork reset');

  await hre.network.provider.request({
    method: 'evm_setNextBlockTimestamp',
    params: [1614290545], // Original block timestamp + 1
  });

  console.log('\t> Timestamp reset to 1614290545');
}

export async function getTimestamp(): Promise<any> {
  const blockNumber = await hre.ethers.provider.send('eth_blockNumber', []);
  const block = await hre.ethers.provider.send('eth_getBlockByNumber', [blockNumber, false]);
  return block.timestamp;
}

export async function setNextBlockTimestamp(timestamp: number): Promise<void> {
  await hre.ethers.provider.send('evm_setNextBlockTimestamp', [timestamp]);
}

export async function mine(blocks: number): Promise<void> {
  for (let i = 0; i < blocks; i++) {
    await hre.ethers.provider.send('evm_mine', []);
  }
}

let snapshotId: string = '0x1';
export async function takeSnapshot() {
  snapshotId = await hre.ethers.provider.send('evm_snapshot', []);
}

export async function revertToSnapshot() {
  await hre.ethers.provider.send('evm_revert', [snapshotId]);
}

export async function getPermitParts(
  nft: string,
  name: string,
  spender: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitParams(nft, name, spender, tokenId, nonce, deadline);
  return await getSig(msgParams);
}

export async function getPermitForAllParts(
  nft: string,
  name: string,
  owner: string,
  operator: string,
  approved: boolean,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPermitForAllParams(nft, name, owner, operator, approved, nonce, deadline);
  return await getSig(msgParams);
}

export async function getBurnWithSigparts(
  nft: string,
  name: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildBurnWithSigParams(nft, name, tokenId, nonce, deadline);
  return await getSig(msgParams);
}

export async function getDelegateBySigParts(
  nft: string,
  name: string,
  delegator: string,
  delegatee: string,
  nonce: number,
  deadline: string
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildDelegateBySigParams(nft, name, delegator, delegatee, nonce, deadline);
  return await getSig(msgParams);
}

const buildDelegateBySigParams = (
  nft: string,
  name: string,
  delegator: string,
  delegatee: string,
  nonce: number,
  deadline: string
) => ({
  types: {
    DelegateBySig: [
      { name: 'delegator', type: 'address' },
      { name: 'delegatee', type: 'address' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    delegator: delegator,
    delegatee: delegatee,
    nonce: nonce,
    deadline: deadline,
  },
});

export function expectEqualArrays(actual: BigNumberish[], expected: BigNumberish[]) {
  if (actual.length != expected.length) {
    logger.throwError(
      `${actual} length ${actual.length} does not match ${expected} length ${expect.length}`
    );
  }

  let areEquals = true;
  for (let i = 0; areEquals && i < actual.length; i++) {
    areEquals = BigNumber.from(actual[i]).eq(BigNumber.from(expected[i]));
  }

  if (!areEquals) {
    logger.throwError(`${actual} does not match ${expected}`);
  }
}

export interface TokenUriMetadataAttribute {
  trait_type: string;
  value: string;
}

export interface ProfileTokenUriMetadata {
  name: string;
  description: string;
  image: string;
  attributes: TokenUriMetadataAttribute[];
}

export async function getMetadataFromBase64TokenUri(
  tokenUri: string
): Promise<ProfileTokenUriMetadata> {
  const splittedTokenUri = tokenUri.split('data:application/json;base64,');
  if (splittedTokenUri.length != 2) {
    logger.throwError('Wrong or unrecognized token URI format');
  } else {
    const jsonMetadataBase64String = splittedTokenUri[1];
    const jsonMetadataBytes = ethers.utils.base64.decode(jsonMetadataBase64String);
    const jsonMetadataString = ethers.utils.toUtf8String(jsonMetadataBytes);
    return JSON.parse(jsonMetadataString);
  }
}

export async function getDecodedSvgImage(tokenUriMetadata: ProfileTokenUriMetadata) {
  const splittedImage = tokenUriMetadata.image.split('data:image/svg+xml;base64,');
  if (splittedImage.length != 2) {
    logger.throwError('Wrong or unrecognized token URI format');
  } else {
    return ethers.utils.toUtf8String(ethers.utils.base64.decode(splittedImage[1]));
  }
}

export function loadTestResourceAsUtf8String(relativePathToResouceDir: string) {
  return readFileSync(join('test', 'resources', relativePathToResouceDir), 'utf8');
}

// Modified from AaveTokenV2 repo
const buildPermitParams = (
  nft: string,
  name: string,
  spender: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
) => ({
  types: {
    Permit: [
      { name: 'spender', type: 'address' },
      { name: 'tokenId', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    spender: spender,
    tokenId: tokenId,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildPermitForAllParams = (
  nft: string,
  name: string,
  owner: string,
  operator: string,
  approved: boolean,
  nonce: number,
  deadline: string
) => ({
  types: {
    PermitForAll: [
      { name: 'owner', type: 'address' },
      { name: 'operator', type: 'address' },
      { name: 'approved', type: 'bool' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    owner: owner,
    operator: operator,
    approved: approved,
    nonce: nonce,
    deadline: deadline,
  },
});

const buildBurnWithSigParams = (
  nft: string,
  name: string,
  tokenId: BigNumberish,
  nonce: number,
  deadline: string
) => ({
  types: {
    BurnWithSig: [
      { name: 'tokenId', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' },
    ],
  },
  domain: {
    name: name,
    version: '1',
    chainId: getChainId(),
    verifyingContract: nft,
  },
  value: {
    tokenId: tokenId,
    nonce: nonce,
    deadline: deadline,
  },
});

async function getSig(msgParams: {
  domain: any;
  types: any;
  value: any;
}): Promise<{ v: number; r: string; s: string }> {
  const sig = await testWallet._signTypedData(msgParams.domain, msgParams.types, msgParams.value);
  return utils.splitSignature(sig);
}
