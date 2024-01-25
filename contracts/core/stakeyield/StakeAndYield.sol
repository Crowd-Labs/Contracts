// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";
import {IBlast} from "../../interfaces/IBlast.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStakeAndYield} from "../../interfaces/IStakeAndYield.sol";

contract StakeAndYield is IStakeAndYield, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal constant BLAST_ADDRESS =
        address(0x4300000000000000000000000000000000000002);
    uint256 internal constant STAKE_PERIOD = 7 days;
    uint256 internal constant BPS_MAX = 10000;
    address public immutable HUBADDR;

    address public _feeReceiver;

    struct RewardStruct {
        uint256 total;
        uint256 claimed;
        uint256 left;
        bytes32 merkleRoot;
        EnumerableSet.AddressSet claimedUser;
    }
    struct StakeEthStruct {
        address staker;
        uint256 stakeAmount;
        uint256 stakeTimeStamp;
    }
    uint256 public _nextRewardId;
    mapping(uint256 => RewardStruct) internal _yieldAndGasReward;
    mapping(uint256 => StakeEthStruct) internal _collectionStakeInfo;

    modifier onlyHub() {
        if (msg.sender != HUBADDR) revert Errors.NotHub();
        _;
    }

    constructor(address hubAddr) {
        if (hubAddr == address(0x0)) revert Errors.NotHub();
        HUBADDR = hubAddr;
        // IBlast(BLAST_ADDRESS).configureAutomaticYield();
        // IBlast(BLAST_ADDRESS).configureClaimableGas();
    }

    function snedStakeEth(
        uint256 collectionId,
        address collectionInitiator
    ) external payable onlyHub {
        StakeEthStruct storage stakeInfo = _collectionStakeInfo[collectionId];
        stakeInfo.staker = collectionInitiator;
        stakeInfo.stakeAmount = msg.value;
        stakeInfo.stakeTimeStamp = block.timestamp;
    }

    function claimStakeEth(uint256 collectionId) external {
        StakeEthStruct storage stakeInfo = _collectionStakeInfo[collectionId];
        if (stakeInfo.staker != msg.sender) revert Errors.NotCollectionOwner();
        if (stakeInfo.stakeTimeStamp + STAKE_PERIOD > block.timestamp)
            revert Errors.NotArriveClaimTime();
        (bool success, ) = msg.sender.call{value: stakeInfo.stakeAmount}("");
        if (!success) revert Errors.SendETHFailed();
        emit Events.ClaimStakeEth(msg.sender, collectionId, block.timestamp);
    }

    function setNewRoundReward(
        uint256 rewardAmount,
        bytes32 merkleRoot
    ) external onlyOwner {
        uint256 rewardId = _nextRewardId++;
        RewardStruct storage re = _yieldAndGasReward[rewardId];
        re.total = rewardAmount;
        re.left = rewardAmount;
        re.merkleRoot = merkleRoot;
        emit Events.SetNewRoundReward(rewardAmount, merkleRoot);
    }

    function claimRedEnvelope(
        uint256 rewardId,
        uint256 claimAmount,
        bytes32[] calldata merkleProof
    ) external {
        if (_yieldAndGasReward[rewardId].merkleRoot == bytes32(0)) {
            revert Errors.EmptyMerkleRoot();
        }
        if (_yieldAndGasReward[rewardId].left == 0) {
            revert Errors.AlreadyFinish();
        }
        if (_yieldAndGasReward[rewardId].left < claimAmount) {
            revert Errors.NotEnoughEth();
        }
        if (_yieldAndGasReward[rewardId].claimedUser.contains(msg.sender)) {
            revert Errors.AlreadyClaimed();
        }
        bytes32 leafNode = keccak256(
            abi.encodePacked(rewardId, msg.sender, claimAmount)
        );
        if (
            !MerkleProof.verify(
                merkleProof,
                _yieldAndGasReward[rewardId].merkleRoot,
                leafNode
            )
        ) {
            revert Errors.MerkleProofVerifyFailed();
        }
        _yieldAndGasReward[rewardId].claimedUser.add(msg.sender);
        _yieldAndGasReward[rewardId].claimed += claimAmount;
        _yieldAndGasReward[rewardId].left -= claimAmount;

        (bool success, ) = msg.sender.call{value: claimAmount}("");
        if (!success) {
            revert Errors.SendETHFailed();
        }

        //clear struct
        if (_yieldAndGasReward[rewardId].left == 0) {
            for (
                uint i = 0;
                i < _yieldAndGasReward[rewardId].claimedUser.length();
                i++
            ) {
                address claimUser = _yieldAndGasReward[rewardId].claimedUser.at(
                    i
                );
                _yieldAndGasReward[rewardId].claimedUser.remove(claimUser);
            }
            delete _yieldAndGasReward[rewardId];
        }
    }

    function claimMaxGas() external {
        IBlast(BLAST_ADDRESS).claimMaxGas(address(0), address(this));
    }
}
