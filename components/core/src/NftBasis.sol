pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

contract NftBasis {
    address static _root;
    uint256 static _codeHashNftData;

    function getInfo() public view returns (address addrRoot, uint256 codeHashNftData) {
        addrRoot = _addrRoot;
        codeHashNftData = _codeHashNftData;
    }

    function destruct(address addr) public onlyOwner {
        selfdestruct(addr);
    }
}