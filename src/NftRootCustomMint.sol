pragma ton-solidity >= 0.52.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './NftRoot.sol';

contract NftRootCustomMint is NftRoot {

    MintType _mintType;
    uint128 _fee;

    constructor(
        MintType mintType,
        uint128 fee,
        string name,
        string descriprion,
        bytes icon,
        address addrAuthor
    ) public override {
        tvm.accept();
        _mintType = mintType;
        _fee = fee;
        _name = name;
        _descriprion = descriprion;
        _icon = icon;
        _addrAuthor = addrAuthor;
        _createChecks();
    }

    function mintNftValidation() internal inline override {
        require(msg.value >= Constants.DEPLOY, Errors.INVALID_VALUE);
        if(_mintType == MintType.OnlyOwner) {
            require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        } else if(_mintType == MintType.OnlyFee) {
            require(msg.sender != _addrOwner, Errors.INVALID_CALLER);
            require(msg.value >= _fee + Constants.DEPLOY, Errors.INVALID_VALUE);
        } else if(_mintType == MintType.OwnerAndFee) {
            require(msg.sender == _addrOwner || msg.value >= _fee + Constants.DEPLOY, Errors.INVALID_CALLER_OR_VALUE);
        }
    }

    function getInfo() public returns (
        string version,
        MintType mintType,
        uint128 fee,
        string name,
        string descriprion,
        bytes icon,
        uint128 totalSupply,
        address addrAuthor,
        address addrOwner
    ) {
        version = _version;
        mintType = _mintType;
        fee = _fee;
        name = _name;
        descriprion = _descriprion;
        icon = _icon;
        totalSupply = _totalSupply;
        addrAuthor = _addrAuthor;
        addrOwner = _addrOwner;
    }
}
