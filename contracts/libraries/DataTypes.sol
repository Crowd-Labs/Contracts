// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library DataTypes {
    enum State {
        OpenForAll,
        CreateCollectionPaused,
        Paused
    }

    struct CreateNewCollectionData {
        uint256 royalty;
        string collInfoURI;
        string collName;
        string collSymbol;
        address derivedRuleModule;
        bytes derivedRuleModuleInitData;
    }

    struct CreateNewNFTData {
        uint256 collectionId;
        string nftInfoURI;
        uint256 derivedFrom;
        bytes derivedModuleData;
        bytes32[] proof;
    }

    struct LimitBurnToken {
        uint256 collectionId;
        uint256 tokenId;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
