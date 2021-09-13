pragma ton-solidity >= 0.43.0;

interface INftRoot {
    function mintNft(int8 wid, uint8 chunks, string mimeType) external;
    function deployBasis(TvmCell codeIndexBasis) external;
    function destructBasis() external view;
    function getInfo() external view returns (uint256 totalMinted);
}
