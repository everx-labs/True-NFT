pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/INft.sol';

contract Nft is INft {
    address _addrRoot;
    address _addrOwner;
    address static _addrNftData;

    constructor() public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 103);
        (address addrRoot, address addrOwner) = optSalt.get().toSlice().decode(address, address);
        require(msg.sender == addrRoot, 100);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
    }

    function getInfo() public view returns (address addrRoot, address addrOwner, address addrNftData) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrNftData = _addrNftData;
    }

    function destruct() public override {
        require(msg.sender == _addrRoot, 100);
        selfdestruct(_addrRoot);
    }
}
