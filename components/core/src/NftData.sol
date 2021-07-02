pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/INftData.sol';

contract NftData is INftData {
    address _addrRoot;
    address _addrOwner;
    address _addrAuthor;
    uint256 static _id;

    constructor(address addrOwner, address addrAuthor) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _addrAuthor = addrAuthor;
    }

    function setOwner(address addrOwner) public override {
        require(msg.sender == _addrRoot);
        _addrOwner = addrOwner;
    }

    function getOwner() public view returns(address addrOwner) {
        addrOwner = _addrOwner;
    }
}