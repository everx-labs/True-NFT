pragma ton-solidity >= 0.52.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';
import './resolvers/DataResolver.sol';

import './IndexBasis.sol';
import './Checks.sol';
import './libraries/Errors.sol';
import './libraries/Constants.sol';

import './interfaces/IData.sol';
import './interfaces/IIndexBasis.sol';
import './interfaces/INftRoot.sol';

abstract contract NftRoot is DataResolver, IndexResolver, INftRoot, Checks {
    address static _addrOwner;
    address _addrAuthor;
    address _addrBasis;

    string _version = "2";
    uint128 _totalSupply = 0;

    string _name;
    string _descriprion;
    bytes _icon;

    bool public _inited = false;

    TvmCell _codeDataChunk;
    TvmCell _codeIndexBasis;

    uint8 constant CHECK_CODE_INDEX = 1;
    uint8 constant CHECK_CODE_INDEX_BASIS = 2;
    uint8 constant CHECK_CODE_DATA = 4;
    uint8 constant CHECK_CODE_DATA_CHUNK = 8;

    function _createChecks() internal inline {
        _checkList =
            CHECK_CODE_INDEX |
            CHECK_CODE_INDEX_BASIS |
            CHECK_CODE_DATA |
            CHECK_CODE_DATA_CHUNK;
    }

    function setCodeIndex(TvmCell code) public {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        _codeIndex = code;
        _passCheck(CHECK_CODE_INDEX);
        _onInit();
        msg.sender.transfer({ value: 0, flag: 64 });
    }
    function setCodeIndexBasis(TvmCell code) public {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        _codeIndexBasis = code;
        _passCheck(CHECK_CODE_INDEX_BASIS);
        _onInit();
        msg.sender.transfer({ value: 0, flag: 64 });
    }
    function setCodeData(TvmCell code) public {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        _codeData = code;
        _passCheck(CHECK_CODE_DATA);
        _onInit();
        msg.sender.transfer({ value: 0, flag: 64 });
    }
    function setCodeDataChunk(TvmCell code) public {
        require(msg.sender == _addrOwner, Errors.INVALID_CALLER);
        require(msg.value >= Constants.PROCESS_MIN, Errors.INVALID_VALUE);
        _codeDataChunk = code;
        _passCheck(CHECK_CODE_DATA_CHUNK);
        _onInit();
        msg.sender.transfer({ value: 0, flag: 64 });
    }

    function _onInit() internal {
        if(_isCheckListEmpty() && !_inited) {
            _inited = true;
            deployBasis();
        }
    }

    function deployBasis() internal inline {
        TvmCell state = tvm.buildStateInit({
            contr: IndexBasis,
            varInit: {
                _codeHashData: resolveCodeHashData(),
                _addrRoot: address(this)
            },
            code: _codeIndexBasis
        });
        _addrBasis = new IndexBasis{stateInit: state, value: Constants.DEPLOY_MIN}();
    }

    function mintNft(
        int8 wid,
        string name,
        string descriprion,
        uint256 contentHash,
        string mimeType,
        uint8 chunks,
        uint128 chunkSize,
        uint128 size,
        Meta meta
    ) public override {
        require(_inited == true, Errors.CONTRACT_NOT_INITED);

        mintNftValidation();
        mintNftLogic();

        address addrData = resolveData(address(this), _totalSupply);

        TvmCell codeData = _buildDataCode(address(this));
        TvmCell stateData = _buildDataState(codeData, _totalSupply);
        new Data{
            stateInit: stateData,
            value: Constants.DEPLOY
        }(
            name,
            descriprion,
            msg.sender,
            msg.sender,
            contentHash,
            mimeType,
            chunks,
            chunkSize,
            size,
            meta,
            _codeIndex,
            _codeDataChunk
        );

        _totalSupply++;
    }

    function mintNftValidation() internal virtual inline {
        require(msg.value >= Constants.DEPLOY + Constants.PROCESS_MIN, Errors.INVALID_VALUE);
    }

    function mintNftLogic() internal virtual inline {
    }
}
