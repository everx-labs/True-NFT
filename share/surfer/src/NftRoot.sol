pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/NftResolver.sol';
import './resolvers/NftDataResolver.sol';

import './interfaces/INft.sol';
import './interfaces/INftData.sol';

import './NftBasis.sol';

struct OnwerChange {
    address addrNftData;
    address addrTo;
}

contract NftRoot is NftResolver, NftDataResolver {
    uint256 _totalGrantedNfts;
    uint256 _totalSupply;

    string _name;
    string _description;
    string _tokenCode;

    uint128 _price;

    address _addrBasis;
    address static _addrOwner;
    // addtNft => OnwerChange
    mapping(address => OnwerChange) _pendingOwners;

    modifier onlyOwner() {
        require(msg.sender == _addrOwner, 101);
        tvm.accept();
        _;
    }

    constructor(
        TvmCell codeNft,
        TvmCell codeNftData,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply
    ) public {
        tvm.accept();
        _codeNft = codeNft;
        _codeNftData = codeNftData;
        _name = name;
        _description = description;
        _tokenCode = tokenCode;
        _totalSupply = totalSupply;
        _price = 1 ton;
    }

    function mintNft(uint64 creationDate, string comment) public onlyOwner {
        TvmCell codeNftData = _buildNftDataCode(address(this));
        TvmCell stateNftData = _buildNftDataState(codeNftData, _totalGrantedNfts);
        address addrNftData = new NftData{stateInit: stateNftData, value: 0.4 ton}(msg.sender, msg.sender, _name, _description, _tokenCode, creationDate, comment);

        TvmCell codeNft = _buildNftCode(address(this), msg.sender);
        TvmCell stateNft = _buildNftState(codeNft, addrNftData);
        new Nft{stateInit: stateNft, value: 0.4 ton}();

        _totalGrantedNfts++;
    }

    function transferOwnership(address addrNft, address addrNftData, address addrTo) public onlyOwner {
        require(resolveNft(address(this), addrNftData, msg.sender) == addrNft, 102);
        _pendingOwners[addrNft] = OnwerChange(addrNftData, addrTo);
        INft(addrNft).destruct();
    }

    function deployBasis(TvmCell codeBasis) public onlyOwner {
        require(msg.value > 0.5 ton, 112);
        uint256 codeHashNftData = resolveCodeHashNftData();
        TvmCell state = tvm.buildStateInit({
            contr: NftBasis,
            varInit: {
                _codeHashNftData: codeHashNftData,
                _addrRoot: address(this)
            },
            code: codeBasis
        });
        _addrBasis = new NftBasis{stateInit: state, value: 0.4 ton}();
    }

    function destructBasis() public view onlyOwner {
        NftBasis(_addrBasis).destruct(_addrOwner);
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

    receive() external {
        optional(OnwerChange) optPendingOwner = _pendingOwners.fetch(msg.sender);
        if(optPendingOwner.hasValue()) {
            OnwerChange pendingOwner = optPendingOwner.get();
            INftData(pendingOwner.addrNftData).setOwner(pendingOwner.addrTo);

            delete _pendingOwners[msg.sender];

            TvmCell codeNft = _buildNftCode(address(this), pendingOwner.addrTo);
            TvmCell stateNft = _buildNftState(codeNft, pendingOwner.addrNftData);
            new Nft{stateInit: stateNft, value: 0.3 ton}();
        }
    }

    function setPrice(uint128 price) public onlyOwner {
        _price = price;
    }

    function burn(address nftDataAddress, address owner) public onlyOwner {
        require(msg.value >= (_price), 223);
        
        TvmCell codeNft = _buildNftCode(address(this), owner);
        TvmCell stateNft = _buildNftState(codeNft, nftDataAddress);
        uint256 hashState = tvm.hash(stateNft);
        address addrNft = address.makeAddrStd(0, hashState);
        Nft(addrNft).destruct();

        NftData(nftDataAddress).destruct
            {value: msg.value, flag: 3, bounce: true}
            (owner);
    }
}
