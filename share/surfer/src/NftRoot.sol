pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';

import './IndexBasis.sol';

import './interfaces/IIndexBasis.sol';

contract NftRoot is DataResolver, IndexResolver {

    uint256 _totalMinted;
    address _addrBasis;

    uint256 _totalGrantedNfts;
    uint256 _totalSupply;

    string _name;
    string _description;
    string _tokenCode;

    uint128 _price;

    address static _addrOwner;

    modifier onlyOwner() {
        require(msg.sender == _addrOwner, 101);
        tvm.accept();
        _;
    }

    constructor(
        TvmCell codeIndex,
        TvmCell codeData,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply
    ) public {
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
        _name = name;
        _description = description;
        _tokenCode = tokenCode;
        _totalSupply = totalSupply;
        _price = 1 ton;
    }

    function mintNft(uint64 creationDate, string comment) public onlyOwner {
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        new Data{stateInit: stateData, value: 1.5 ton}(msg.sender, _codeIndex, msg.sender, _name, _description, _tokenCode, creationDate, comment);

        _totalMinted++;
    }

    function deployBasis(TvmCell codeIndexBasis) public {
        require(msg.value > 0.5 ton, 104);
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

    function destructBasis() public view {
        IIndexBasis(_addrBasis).destruct();
    }

    function getInfo() public view returns (
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply,
        uint256 totalGrantedNfts,
        uint128 price
    ) {
        name = _name;
        description = _description;
        tokenCode = _tokenCode;
        totalSupply = _totalSupply;
        totalGrantedNfts = _totalGrantedNfts;
        price = _price;
    }

    function setPrice(uint128 price) public onlyOwner {
        _price = price;
    }

    function burn(address dataAddress, address owner) public onlyOwner {
        require(msg.value >= (_price), 223);

        Data(dataAddress).destruct
            {value: msg.value, flag: 3, bounce: true}
            (owner);
    }
}
