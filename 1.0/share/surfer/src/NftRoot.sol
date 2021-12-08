pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';

import './IndexBasis.sol';

import './interfaces/IIndexBasis.sol';

import './libraries/Constants.sol';
import './libraries/Errors.sol';

contract NftRoot is DataResolver, IndexResolver {

    uint256 _totalMinted;
    address _addrBasis;

    uint256 _totalSupply;

    string _name;
    string _description;
    string _tokenCode;

    //index => part of image
    mapping(uint128 => bytes) _content;

    uint128 _price;

    address static _addrOwner;

    modifier onlyOwner() {
        require(msg.sender == _addrOwner, Errors.ERROR_MESSAGE_SENDER_IS_NOT_OWNER);
        tvm.accept();
        _;
    }

    constructor(
        TvmCell codeIndex,
        TvmCell codeData,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply,
        uint128 index,
        bytes part
    ) public {
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
        _name = name;
        _description = description;
        _tokenCode = tokenCode;
        _totalSupply = totalSupply;

        _content[index] = part;
        
        _price = 1 ton;
    }

    function mintNft(uint64 creationDate, string comment, address owner) public onlyOwner {
        require(msg.value >= 1.6 ton, Errors.ERROR_NOT_ENOUGH_GRAMS);
        require(_totalMinted <= _totalSupply, Errors.ERROR_MINTED_TOO_MUCH);
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        new Data
            {stateInit: stateData, value: 1.5 ton} (
                owner,
                _codeIndex,
                msg.sender,
                _name,
                _description,
                _tokenCode,
                creationDate,
                comment,
                0,
                _content[0]
            );

        _totalMinted++;
    }

    function deployBasis(TvmCell codeIndexBasis) public onlyOwner {
        require(msg.value > 0.5 ton, Errors.ERROR_NOT_ENOUGH_GRAMS);
        uint256 codeHasData = resolveCodeHashData();
        TvmCell state = tvm.buildStateInit({
            contr: IndexBasis,
            varInit: {
                _codeHashData: codeHasData,
                _addrRoot: address(this)
            },
            code: codeIndexBasis
        });
        _addrBasis = new IndexBasis{stateInit: state, value: 0.4 ton}();
    }

    function destructBasis() public view onlyOwner {
        IIndexBasis(_addrBasis).destruct();
    }

    function getInfo() public view returns (
        mapping(uint128 => bytes) content,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply,
        uint128 price
    ) {
        content = _content;
        name = _name;
        description = _description;
        tokenCode = _tokenCode;
        totalSupply = _totalSupply;
        price = _price;
    }

    function setPrice(uint128 price) public onlyOwner {
        _price = price;
    }

    function burn(address dataAddress, address owner) public onlyOwner {
        require(msg.value >= (_price), Errors.ERROR_MSG_VALUE_LESS_THAN_PRICE);

        Data(dataAddress).destruct
            {value: msg.value, flag: 3, bounce: true}
            (owner);
    }
}
