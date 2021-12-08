pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';
import './resolvers/StorageResolver.sol';

import './IndexBasis.sol';

import './interfaces/IData.sol';
import './interfaces/IIndexBasis.sol';
import './interfaces/INftRoot.sol';

contract NftRoot is DataResolver, IndexResolver, StorageResolver, INftRoot {

    address static _addrOwner;
    uint256 _totalMinted;
    address public _addrBasis;

    constructor(TvmCell codeIndex, TvmCell codeData, TvmCell codeStorage) public {
        tvm.accept();
        _codeIndex = codeIndex;
        _codeData = codeData;
        _codeStorage = codeStorage;
    }

    function mintNft(int8 wid, uint8 chunks, string mimeType) public override {
        require(msg.value >= 2.3 ton, 108);
        require(msg.sender == _addrOwner, 100);
        address addrData = resolveData(address(this), _totalMinted);
        address addrStorage = resolveStorage(address(this), addrData, _addrOwner);
        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalMinted);
        new Data{
            stateInit: stateData,
            value: 1.1 ton
        }(msg.sender, addrStorage, _codeIndex);

        TvmCell codeStorage = _buildStorageCode(address(this), _addrOwner);
        TvmCell stateStorage = _buildStorageState(codeStorage, addrData);
        TvmCell payloadStorage = _buildStoragePayload(chunks, mimeType);
        tvm.deploy(stateStorage, payloadStorage, 1.1 ton, wid);

        _totalMinted++;
    }

    function deployBasis(TvmCell codeIndexBasis) public override {
        require(msg.sender == _addrOwner, 100);
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

    function destructBasis() public override view {
        require(msg.sender == _addrOwner, 100);
        IIndexBasis(_addrBasis).destruct();
    }

    function getInfo() public override view returns (uint256 totalMinted) {
        totalMinted = _totalMinted;
    }
}