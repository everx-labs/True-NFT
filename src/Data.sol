pragma ton-solidity >= 0.52.0;

import './resolvers/IndexResolver.sol';
import './resolvers/DataChunkResolver.sol';

import './interfaces/IData.sol';

import './libraries/Errors.sol';
import './libraries/Constants.sol';


contract Data is IData, IndexResolver, DataChunkResolver {

    string _version = "2";
    string _name;
    string _descriprion;
    address _addrOwner;
    address _addrAuthor;
    uint128 _createdAt;
    address _addrRoot;
    uint256 _contentHash;
    string _mimeType;
    uint8 _chunks;
    uint128 _chunkSize;
    uint128 _size;
    Meta _meta;

    uint256 static public _id;

    bool public _deployed;

    uint128 _royalty;
    uint128 _royaltyMin;

    bool _onSale;
    uint128 _price;

    constructor(
        string name,
        string descriprion,
        address addrOwner,
        address addrAuthor,
        uint256 contentHash,
        string mimeType,
        uint8 chunks,
        uint128 chunkSize,
        uint128 size,
        Meta meta,
        TvmCell codeIndex,
        TvmCell codeDataChunk
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), Errors.CONTRACT_CODE_NOT_SALTED);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, Errors.INVALID_CALLER);
        require(msg.value >= Constants.DEPLOY_SM, Errors.INVALID_VALUE);

        _name = name;
        _descriprion = descriprion;
        _addrOwner = addrOwner;
        _addrAuthor = addrAuthor;
        _createdAt = uint128(now);
        _addrRoot = addrRoot;
        _contentHash = contentHash;
        _mimeType = mimeType;
        _chunks = chunks;
        _chunkSize = chunkSize;
        _size = size;
        _meta = meta;

        _codeIndex = codeIndex;
        _codeDataChunk = codeDataChunk;

        deployIndex(addrOwner);
    }

    function setRoyalty(uint128 royalty, uint128 royaltyMin) public override {
        require(msg.sender == _addrAuthor, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        require(_royalty <= 100000, Errors.INVALID_ARGUMENTS);
        require(_royalty == 0 && _royaltyMin == 0, Errors.ROYALTY_ALREADY_SET);

        _royalty = royalty;
        _royaltyMin = royaltyMin;

        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function putOnSale(uint128 price) public override {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);

        _price = price;
        _onSale = true;

        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function removeFromSale() public override {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        require(_onSale == true, Errors.CONTRACT_IS_NOT_ON_SALE);

        _price = 0;
        _onSale = false;

        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function buy() public override {
        require(msg.sender != address(0), Errors.INVALID_CALLER);
        require(
            msg.value >= (uint256(_price * _royalty / 100000) < _royaltyMin ? _royaltyMin : _price * _royalty / 100000) + Constants.PROCESS_MIN,
            Errors.INVALID_VALUE
        );
        require(_onSale == true, Errors.CONTRACT_IS_NOT_ON_SALE);

        _price = 0;
        _onSale = false;

        // msg.sender.transfer({ value: 0, flag: 64 });
    }

    function transfer(address addrTo) public override {
        transferValidation();
        transferLogic();

        address oldIndexOwner = resolveIndex(
            _addrRoot,
            address(this),
            _addrOwner
        );
        IIndex(oldIndexOwner).destruct();
        address oldIndexOwnerRoot = resolveIndex(
            address(0),
            address(this),
            _addrOwner
        );
        IIndex(oldIndexOwnerRoot).destruct();

        _addrOwner = addrTo;

        deployIndex(addrTo);
    }

    function transferValidation() internal virtual inline {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.DEPLOY_SM, Errors.INVALID_VALUE);
        require(_onSale == true, Errors.CONTRACT_IS_ON_SALE);
    }

    function transferLogic() internal virtual inline {
    }

    function deployIndex(address owner) internal {
        TvmCell codeIndexOwner = _buildIndexCode(_addrRoot, owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: Constants.DEPLOY_MIN}(_addrRoot);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: Constants.DEPLOY_MIN}(_addrRoot);
    }

    function deployDataChunk(bytes chunk, uint128 chunkNumber) public override {
        require(msg.sender == _addrAuthor, Errors.INVALID_CALLER);
        require(msg.value >= Constants.DEPLOY_MIN + Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        TvmCell state = _buildDataChunkState(address(this), chunkNumber);

        new DataChunk
            {stateInit: state, value: Constants.DEPLOY_MIN}
            (chunk);

        // msg.sender.transfer({ value: 0, flag: 64 });
    }

    function getInfo() public view returns (
        string version,
        string name,
        string descriprion,
        address addrOwner,
        address addrAuthor,
        uint128 createdAt,
        address addrRoot,
        uint256 contentHash,
        string mimeType,
        uint8 chunks,
        uint128 chunkSize,
        uint128 size,
        Meta meta,
        uint128 royalty,
        uint128 royaltyMin
    ) {
        version = _version;
        name = _name;
        descriprion = _descriprion;
        addrOwner = _addrOwner;
        addrAuthor = _addrAuthor;
        createdAt = _createdAt;
        addrRoot = _addrRoot;
        contentHash = _contentHash;
        mimeType = _mimeType;
        chunks = _chunks;
        chunkSize = _chunkSize;
        size = _size;
        meta = _meta;
        royalty = _royalty;
        royaltyMin = _royaltyMin;
    }
}
