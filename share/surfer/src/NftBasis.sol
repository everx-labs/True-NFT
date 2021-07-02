pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

contract NftBasis {
    address static _addrRoot;
    uint256 static _codeHashNftData;

    modifier onlyRoot() {
        require(msg.sender == _addrRoot, 100);
        tvm.accept();
        _;
    }

    constructor() public onlyRoot {
    }

    function getInfo() public view returns (address addrRoot, uint256 codeHashNftData) {
        addrRoot = _addrRoot;
        codeHashNftData = _codeHashNftData;
    }

    function destruct(address recipient) public onlyRoot {
        selfdestruct(recipient);
    }
}
