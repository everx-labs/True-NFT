pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/IIndex.sol';

import './libraries/Errors.sol';

contract Index is IIndex {
    address _addrRoot;
    address _addrOwner;
    address static _addrData;

    constructor(address root) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), Errors.ERROR_EMPTY_SALT);
        (address addrRoot, address addrOwner) = optSalt
            .get()
            .toSlice()
            .decode(address, address);
        require(msg.sender == _addrData, Errors.ERROR_MESSAGE_SENDER_IS_NOT_OWNER);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        if(addrRoot == address(0)) {
            _addrRoot = root;
        }
    }

    function getInfo() public view override returns (
        address addrRoot,
        address addrOwner,
        address addrData
    ) {
        addrRoot = _addrRoot;
        addrOwner = _addrOwner;
        addrData = _addrData;
    }

    function destruct() public override {
        require(msg.sender == _addrData, Errors.ERROR_MESSAGE_SENDER_IS_NOT_OWNER);
        selfdestruct(_addrData);
    }
}