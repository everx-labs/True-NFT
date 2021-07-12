pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

contract IndexBasis {
    address static _addrRoot;
    uint256 static _codeHashData;

    modifier onlyRoot() {
        require(msg.sender == _addrRoot, 100);
        tvm.accept();
        _;
    }

    constructor() public onlyRoot {}

    function getInfo() public view returns (address addrRoot, uint256 codeHashData) {
        addrRoot = _addrRoot;
        codeHashData = _codeHashData;
    }

    function destruct() public onlyRoot {
        selfdestruct(_addrRoot);
    }
}