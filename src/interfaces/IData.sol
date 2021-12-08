pragma ton-solidity >= 0.52.0;

struct Meta {
    uint128 height;
    uint128 width;
    uint128 duration;
    string extra;
    string json;
}

interface IData {
    function transfer(address addrTo) external;
    function deployDataChunk(bytes chunk, uint128 chunkNumber) external;
    function setRoyalty(uint128 royalty, uint128 royaltyMin) external;
    function putOnSale(uint128 price) external;
    function removeFromSale() external;
    function buy() external;
}
