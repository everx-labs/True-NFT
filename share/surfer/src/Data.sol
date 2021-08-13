pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';

import './interfaces/IData.sol';

import './libraries/Constants.sol';
import './libraries/Errors.sol';

contract Data is IData, IndexResolver {
    address _addrRoot;
    address _addrOwner;
    address _addrAuthor;
    uint256 static _id;

    string _name;
    string _description;
    string _tokenCode;
    uint64 _creationDate;
    string _comment;

    //index => part of image
    mapping(uint128 => bytes) _content;

    constructor(
        address addrOwner,
        TvmCell codeIndex,
        address addrAuthor,
        string name,
        string description,
        string tokenCode,
        uint64 creationDate,
        string comment,
        uint128 index,
        bytes part
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), Errors.ERROR_EMPTY_SALT);
        (address addrRoot) = optSalt
            .get()
            .toSlice()
            .decode(address);
        require(msg.sender == addrRoot, Errors.ERROR_MESSAGE_SENDER_IS_NOT_ROOT);
        require(msg.value >= Constants.MIN_FOR_DEPLOY);
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _addrAuthor = addrAuthor;
        _name = name;
        _description = description;
        _tokenCode = tokenCode;
        _creationDate = creationDate;
        _comment = comment;
        _codeIndex = codeIndex;

        _content[index] = part;

        deployIndex(addrOwner);
    }

    function deployIndex(address owner) private {
        TvmCell codeIndexOwner = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index
            {stateInit: stateIndexOwner, value: Constants.DEPLOY_INDEX_FEE, flag: 0}
            (_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index
            {stateInit: stateIndexOwnerRoot, value: Constants.DEPLOY_INDEX_FEE, flag: 0}
            (_addrRoot);
    }

    function destruct(address recipient) public {
        require(msg.sender == _addrRoot, Errors.ERROR_MESSAGE_SENDER_IS_NOT_ROOT);

        address oldIndexOwner = resolveIndex(address(0), address(this), _addrOwner);
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(_addrRoot, address(this), _addrOwner);
        IIndex(oldIndexOwnerRoot).destruct();

        recipient.transfer(0, false, 64);
        selfdestruct(recipient);
    }

    function getOwner() public view override returns(address addrOwner, address addrNftData) {
        addrOwner = _addrOwner;
        addrNftData = address(this);
    }

    function getInfo() public view override
    returns(
        mapping(uint128 => bytes) content,
        address author,
        string name,
        string description,
        string tokenCode,
        uint64 creationDate,
        string comment
    ) {
        content = _content;
        author = _addrAuthor;
        name = _name;
        description = _description;
        tokenCode = _tokenCode;
        creationDate = _creationDate;
        comment = _comment;
    }
}
