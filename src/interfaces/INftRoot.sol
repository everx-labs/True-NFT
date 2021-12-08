pragma ton-solidity >= 0.52.0;

import './IData.sol';

enum MintType { OnlyOwner, OnlyFee, OwnerAndFee, All }

interface INftRoot {
    function mintNft(
        int8 wid,
        string name,
        string descriprion,
        uint256 contentHash,
        string mimeType,
        uint8 chunks,
        uint128 chunkSize,
        uint128 size,
        Meta meta
    ) external;
}
