pragma ton-solidity >= 0.52.0;

interface IDataChunk {
    function getInfo() external view returns (
        address addrContent,
        uint128 chunkNumber,
        bytes chunk
    );
}
