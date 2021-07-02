pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../../../components/debots/src/Debot.sol";
import "../../../components/debots/src/Terminal.sol";
import "../../../components/debots/src/Menu.sol";
import "../../../components/debots/src/Msg.sol";
import "../../../components/debots/src/ConfirmInput.sol";
import "../../../components/debots/src/AddressInput.sol";
import "../../../components/debots/src/NumberInput.sol";
import "../../../components/debots/src/AmountInput.sol";
import "../../../components/debots/src/Sdk.sol";
import "../../../components/debots/src/Upgradable.sol";
import "../../../components/debots/src/UserInfo.sol";
import "../../../components/debots/src/SigningBoxInput.sol";

import "./NftRoot.sol";
import "./NftBasis.sol";
import "./NftData.sol";
import "./Nft.sol";

interface IMultisig {
    function submitTransaction(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload)
    external returns (uint64 transId);

    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload)
    external;
}

interface IManager {
    function deployRoot(
        address addrOwner,
        TvmCell codeNft,
        TvmCell codeNftData,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply
    ) external;
}

struct RootParams {
    address addrOwner;
    string name;
    string description;
    string tokenCode;
    uint256 totalSupply;
}

struct TransferParams {
    address addrNft;
    address addrNftData;
    address addrTo;
}

struct NftParams {
    uint64 creationDate;
    string comment;
}

struct NftResp {
    address addrNftData;
    address owner;
}

contract NftDebot is Debot, Upgradable {

    TvmCell _codeNFTRoot;
    TvmCell _codeBasis;
    TvmCell _codeNftData;
    TvmCell _codeNft;

    address _addrNFTRoot;
    uint256 _totalMinted;

    bytes _surfContent;

    address _addrMultisig;
    address _addrManager;

    uint32 _keyHandle;

    address _nftAddr;

    uint128 _price;

    RootParams _rootParams;
    TransferParams _transferParams;
    NftParams _nftParams;
    NftResp[] _owners;

    modifier accept {
        tvm.accept();
        _;
    }

    /*
    * Uploaders
    */

    function setNftRootCode(TvmCell code) public accept {
        _codeNFTRoot = code;
    }
    function setBasisCode(TvmCell code) public accept {
        _codeBasis = code;
    }
    function setNftDataCode(TvmCell code) public accept {
        _codeNftData = code;
    }
    function setNftCode(TvmCell code) public accept {
        _codeNft = code;
    }
    function setManager(address addr) public accept {
        _addrManager = addr;
    }
    function setContent(bytes surfContent) public accept {
        _surfContent = surfContent;
    }

    /*
     *  Overrided Debot functions
     */

    /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Medal admin Debot";
        version = "1.0.0";
        publisher = "";
        key = "";
        author = "";
        support = address.makeAddrStd(0, 0x0);
        hello = "Hello, I'm Medal admin DeBot";
        language = "en";
        dabi = m_debotAbi.get();
        icon = "";
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID, ConfirmInput.ID ];
    }

    function start() public override {
        mainMenu(0);
    }

    function mainMenu(uint32 index) public {
        index;
        if(_addrMultisig == address(0)) {
            Terminal.print(0, 'You need to attach Multisig');
            attachMultisig();
        } else {
            restart();
        }
    }
    function restart() public {
        if(_keyHandle == 0) {
            uint[] none;
            SigningBoxInput.get(tvm.functionId(setKeyHandle), "Enter keys to sign all operations.", none);
            return;
        }
        resolveNFTRoot();
        checkContract(_addrNFTRoot);
    }
    function checkContract(address addr) public {
        Sdk.getAccountType(tvm.functionId(checkRootContract), addr);
    }
    function checkRootContract(int8 acc_type) public {
        MenuItem[] _items;
        if (acc_type == -1 || acc_type == 0 || acc_type == 2) {
            _items.push(MenuItem("Deploy  Token", "", tvm.functionId(deployRoot)));
        } else {
            _items.push(MenuItem("Mint  Nft", "", tvm.functionId(deployNft)));
            _items.push(MenuItem("Get all Nft", "", tvm.functionId(getAllNftData)));
            _items.push(MenuItem("Set burn price", "", tvm.functionId(setBurnPrice)));
            _items.push(MenuItem("Burn owner`s nfts", "", tvm.functionId(burnNftsOfOwner)));
        }
        Menu.select("==What to do?==", "", _items);
    }

    //=========================================================================

    function deployRoot(uint32 index) public {
        index;
        MenuItem[] items;
        _rootParams.addrOwner = _addrMultisig;
        if(_rootParams.name == '') {
            items.push(MenuItem("Enter token name:", "", tvm.functionId(rootParamsInputName)));
        }
        if(_rootParams.description == '') {
            items.push(MenuItem("Enter token description:", "", tvm.functionId(rootParamsInputDesc)));
        }
        if(_rootParams.tokenCode == '') {
            items.push(MenuItem("Enter token code:", "", tvm.functionId(rootParamsInputTokenCode)));
        }
        if(_rootParams.totalSupply == uint256(0)) {
            items.push(MenuItem("Enter total supply:", "", tvm.functionId(rootParamsInputTotalSupply)));
        }
        Menu.select("==What to do?==", "", items);
        this.deployRootStep1();
    }

    function rootParamsInputName(uint32 index) public {
        index;
        Terminal.input(tvm.functionId(rootParamsSetName), "Enter token name:", false);
    }
    function rootParamsInputDesc(uint32 index) public {
        index;
        Terminal.input(tvm.functionId(rootParamsSetDesc), "Enter token description:", false);
    }
    function rootParamsInputTokenCode(uint32 index) public {
        index;
        Terminal.input(tvm.functionId(rootParamsSetTokenCode), "Enter token code:", false);
    }
    function rootParamsInputTotalSupply(uint32 index) public {
        index;
        AmountInput.get(tvm.functionId(rootParamsSetTotalSupply), "Enter total supply:", 0, 0, 1000);
    }

    function rootParamsSetName(string value) public {
        _rootParams.name = value;
    }
    function rootParamsSetDesc(string value) public {
        _rootParams.description = value;
    }
    function rootParamsSetTokenCode(string value) public {
        _rootParams.tokenCode = value;
    }
    function rootParamsSetTotalSupply(uint256 value) public {
        _rootParams.totalSupply = value;
    }

    function deployRootStep1() public {
        this.deployRootStep2();
    }

    function deployRootStep2() public {
        Terminal.print(0, 'Let`s check data.');
        Terminal.print(0, format('\nOwner address: {}', _rootParams.addrOwner));
        Terminal.print(0, format('Root name: {}', _rootParams.name));
        Terminal.print(0, format('Root description: {}', _rootParams.description));
        Terminal.print(0, format('Root tokenCode: {}', _rootParams.tokenCode));
        Terminal.print(0, format('Root totalSupply: {}', _rootParams.totalSupply));
        Terminal.print(0, format("Root address: {}\n", _addrNFTRoot));
        this.checkRootParams(0);
    }

    function deployRootStep3(bool value) public {
        if(value) {
            TvmCell payload = tvm.encodeBody(
                IManager.deployRoot,
                _rootParams.addrOwner,
                _codeNft,
                _codeNftData,
                _rootParams.name,
                _rootParams.description,
                _rootParams.tokenCode,
                _rootParams.totalSupply
            );
            optional(uint256) none;
            IMultisig(_addrMultisig).sendTransaction {
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: 0,
                expire: 0,
                callbackId: tvm.functionId(onRootDeploySuccess),
                onErrorId: tvm.functionId(onError),
                signBoxHandle: _keyHandle
            }(_addrManager, 0.5 ton, false, 3, payload);
        } else {
            MenuItem[] items;
            items.push(MenuItem("Enter token name:", "", tvm.functionId(rootParamsInputName)));
            items.push(MenuItem("Enter token description:", "", tvm.functionId(rootParamsInputDesc)));
            items.push(MenuItem("Enter token code:", "", tvm.functionId(rootParamsInputTokenCode)));
            items.push(MenuItem("Enter total supply:", "", tvm.functionId(rootParamsInputTotalSupply)));
            Menu.select("==What to do?==", "", items);
            this.deployRootStep1();
        }
    }
    function onRootDeploySuccess() public {
        Terminal.print(0, "Root deployed!");
        this.deployRootStep4();
    }
    function deployRootStep4() public {
        TvmCell payload = tvm.encodeBody(
                NftRoot.deployBasis,
                _codeBasis
            );
            optional(uint256) none;
            IMultisig(_addrMultisig).sendTransaction {
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: 0,
                expire: 0,
                callbackId: tvm.functionId(onBasisDeploySuccess),
                onErrorId: tvm.functionId(onError),
                signBoxHandle: _keyHandle
            }(_addrNFTRoot, 1 ton, false, 3, payload);
    }
    function onBasisDeploySuccess() public {
        Terminal.print(0, "Basis deployed!");
        restart();
    }

    //=========================================================================

    function deployNft(uint32 index) public {
        index;
        resolveNftDataAddr();
        resolveNftAddr();
        _nftParams.creationDate = uint64(now);
        MenuItem[] items;
        items.push(MenuItem("Comment:", "", tvm.functionId(nftParamsInputComment)));
        Menu.select("==What to do?==", "", items);
        this.deployNftStep1();
    }
     function nftParamsInputComment(uint32 index) public {
        index;
        Terminal.input(tvm.functionId(nftParamsSetComment), "Enter comment:", false);
    }
    function nftParamsSetComment(string value) public {
        _nftParams.comment = value;
    }

    function deployNftStep1() public {
        this.deployNftStep2();
    }

    function deployNftStep2() public {
        Terminal.print(0, 'Let`s check data.');
        Terminal.print(0, format("NftData address: {}", _transferParams.addrNftData));
        Terminal.print(0, format("Comment: {}", _nftParams.comment));
        Terminal.print(0, format("Date of creation Nft: {}\n", _nftParams.creationDate));
        ConfirmInput.get(tvm.functionId(deployNftStep3), "Sign and deploy Root?");
    }

    function deployNftStep3(bool value) public {
        if(value) {
            this.deployNftStep4(value);
        } else {
            this.deployNft(0);
        }
    }

    function deployNftStep4(bool value) public {
        if(value) {
            TvmCell payload = tvm.encodeBody(
                NftRoot.mintNft,
                _nftParams.creationDate,
                _nftParams.comment
            );
            optional(uint256) none;
            IMultisig(_addrMultisig).sendTransaction {
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: none,
                time: 0,
                expire: 0,
                callbackId: tvm.functionId(onNftDeploySuccess),
                onErrorId: tvm.functionId(onError),
                signBoxHandle: _keyHandle
            }(_addrNFTRoot, 2 ton, true, 3, payload);
        } else {
            Terminal.print(0, format("NftData address: {}", _transferParams.addrNftData));
            Terminal.print(0, "Wait for deploy....");
            ConfirmInput.get(tvm.functionId(deployNftStep5), "Check contract status?");
        }
    }
    function onNftDeploySuccess() public {
        _totalMinted++;
        this.deployNftStep5(true);
    }
    function deployNftStep5(bool value) public {
        if(value) {
            this.checkNftData(_transferParams.addrNftData);
        } else {
            this.fillContent(0);
        }
    }
    function checkNftData(address addr) public {
        Sdk.getAccountType(tvm.functionId(checkNftDataContract), addr);
    }
    function checkNftDataContract(int8 acc_type) public {
        if (acc_type == -1 || acc_type == 0 || acc_type == 2) {
            Terminal.print(0, "Wait a minute!");
            this.deployNftStep4(false);
        } else {
            Terminal.print(0, "Nft deployed!");
            this.fillContent(0);
        }
    }

    //=========================================================================

    function fillContent(uint32 index) public {
        index;
        Terminal.print(0, "Fill the surf icon");
        TvmCell payload = tvm.encodeBody(
            NftData.setNftDataContent,
            0,
            _surfContent
        );
        optional(uint256) none;
        IMultisig(_addrMultisig).sendTransaction {
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(onFillContentSuccess),
            onErrorId: tvm.functionId(onError),
            signBoxHandle: _keyHandle
        }(_transferParams.addrNftData, 2 ton, false, 3, payload);
    }

    function onFillContentSuccess() public {
        Terminal.print(0, format("Picture uploaded!\nAddress of nftData:\n{}", _transferParams.addrNftData));
        this.transferOwnership(0);
    }

    //=========================================================================

    function transferOwnership(uint32 index) public {
        index;
        AddressInput.get(tvm.functionId(transferParamsSetRecipientAddress), "Enter recipient address:");
        this.transferOwnershipStep1(0);
    }
    function transferParamsSetRecipientAddress(address value) public {
        _transferParams.addrTo = value;
    }

    function transferOwnershipStep1(uint32 index) public {
        index;
        TvmCell payload = tvm.encodeBody(
            NftRoot.transferOwnership,
            _transferParams.addrNft,
            _transferParams.addrNftData,
            _transferParams.addrTo
        );
        optional(uint256) none;
        IMultisig(_addrMultisig).sendTransaction {
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(onTransferSuccess),
            onErrorId: tvm.functionId(onError),
            signBoxHandle: _keyHandle
        }(_addrNFTRoot, 2 ton, true, 3, payload);
    }
    function onTransferSuccess() public {
        Terminal.print(0, "Done!");
        restart();
    }

    //=========================================================================

    function getAllNftData(uint32 index) public {
        index;
        delete _owners;
        TvmBuilder salt;
        salt.store(_addrNFTRoot);
        TvmCell code = tvm.setCodeSalt(_codeNftData, salt.toCell());
        uint256 codeHashNftData = tvm.hash(code);
        Sdk.getAccountsDataByHash(tvm.functionId(getNftDataByHash), codeHashNftData, address(0x0));
    }
    function getNftDataByHash(ISdk.AccData[] accounts) public {
        for (uint i = 0; i < accounts.length; i++)
        {
            getNftData(accounts[i].id);
        }
        this.printNftData();
    }
    function getNftData(address addrNftData) public {
        NftData(addrNftData).getOwner{
            abiVer: 2,
            extMsg: true,
            callbackId: tvm.functionId(setNftData),
            onErrorId: 0,
            time: 0,
            expire: 0,
            sign: false
        }();
    }
    function setNftData(address addrOwner, address addrNftData) public {
        _owners.push(NftResp(addrNftData, addrOwner));
    }
    function printNftData() public {
        for (uint i = 0; i < _owners.length; i++) {
            string str = _buildNftDataPrint(i, _owners[i].addrNftData, _owners[i].owner);
            Terminal.print(0, str);
        }
        MenuItem[] items;
        items.push(MenuItem("Return to main menu:", "", tvm.functionId(mainMenu)));
        items.push(MenuItem("Burn nft", "", tvm.functionId(burnOneNft)));
        Menu.select("==What to do?==", "", items);
    }
    function _buildNftDataPrint(uint id, address nftData, address ownerAddress) public returns (string str) {
        str = format("Index: {}\nNft: {}\nOwner: {}\n", id, nftData, ownerAddress);
    }

    //==========================================================================

    function setBurnPrice(uint32 index) public {
        AmountInput.get(tvm.functionId(setBurnPriceStep1), "Enter burn price:", 0, 0, 0xFFFFFFFF);
    }
    function setBurnPriceStep1(uint128 value) public {
        _price = value;
        this.setBurnPriceStep2();
    }
    function setBurnPriceStep2() public {
        TvmCell payload = tvm.encodeBody(
            NftRoot.setPrice,
            _price
        );
        optional(uint256) none;
        IMultisig(_addrMultisig).sendTransaction {
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(onSetPriceSuccess),
            onErrorId: tvm.functionId(onError),
            signBoxHandle: _keyHandle
        }(_addrNFTRoot, 2 ton, true, 3, payload);
    }
    function onSetPriceSuccess() public {
        Terminal.print(0, "Price updated!");
        restart();
    }

    //==========================================================================

    function burnOneNft(uint32 index) public {
        index;
        AmountInput.get(tvm.functionId(burnOneNftStep1), "Enter index of nft:", 0, 0, 0xFFFFFFFF);
    }
    function burnOneNftStep1(uint128 value) public {
        NftResp candidate = _owners[uint(value)];
        Terminal.print(0, format("AddrNft: {}\nOwner: {}", candidate.addrNftData, candidate.owner));
        this.burnOneNftStep2(candidate);
    }
    function burnOneNftStep2(NftResp candidate) public {
        TvmCell payload = tvm.encodeBody(
            NftRoot.burn,
            candidate.addrNftData,
            candidate.owner
        );
        optional(uint256) none;
        IMultisig(_addrMultisig).sendTransaction {
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: none,
            time: 0,
            expire: 0,
            callbackId: tvm.functionId(onBurnSuccess),
            onErrorId: tvm.functionId(onError),
            signBoxHandle: _keyHandle
        }(_addrNFTRoot, 2 ton, true, 3, payload);
    }
    function onBurnSuccess() public {
        Terminal.print(0, "Burned!");
        restart();
    }

    //==========================================================================

    function burnNftsOfOwner(uint32 index) public {
        index;
        Terminal.print(0, "Will be implemented in the future!");
        restart();
    }

    //=========================================================================

    /*
    * Resolvers
    */

    function resolveNFTRoot() public {
        _addrNFTRoot = address.makeAddrStd(0, tvm.hash(makeStateInit()));
    }
    function makeStateInit() public view returns (TvmCell state){
        state = tvm.buildStateInit({
            contr: NftRoot,
            varInit: {
                _addrOwner: _addrMultisig
            },
            code: _codeNFTRoot
        });
    }

    function resolveNftDataAddr() public {
        TvmBuilder salt;
        salt.store(_addrNFTRoot);
        TvmCell codeNftData = tvm.setCodeSalt(_codeNftData, salt.toCell());
        TvmCell stateNftData = tvm.buildStateInit({
            contr: NftData,
            varInit: {_id: _totalMinted},
            code: codeNftData
        });
        uint256 hashStateNftData = tvm.hash(stateNftData);
        _transferParams.addrNftData = address.makeAddrStd(0, hashStateNftData);
    }

    function resolveNftAddr() public {
        TvmBuilder salt;
        salt.store(_addrNFTRoot);
        salt.store(_addrMultisig);
        TvmCell codeNft = tvm.setCodeSalt(_codeNft, salt.toCell());
        TvmCell stateNft = tvm.buildStateInit({
            contr: Nft,
            varInit: {_addrNftData: _transferParams.addrNftData},
            code: codeNft
        });
        uint256 hashStateNft = tvm.hash(stateNft);
        _transferParams.addrNft = address.makeAddrStd(0, hashStateNft);
    }

    /*
    * helpers
    */

    function checkRootParams(uint32 index) public {
        index;
        if( _rootParams.addrOwner != address(0) &&
            _rootParams.name != '' &&
            _rootParams.description != '' &&
            _rootParams.tokenCode != '' &&
            _rootParams.totalSupply != uint256(0)
        ) {
            ConfirmInput.get(tvm.functionId(deployRootStep3), "Sign and deploy Root?");
        } else {
            this.deployRoot(0);
        }
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Sdk error {}. Exit code {}.", sdkError, exitCode));
        restart();
    }

    function attachMultisig() public {
        AddressInput.get(tvm.functionId(saveMultisig), "Attach Multisig\nEnter address:");
    }

    function saveMultisig(address value) public {
        _addrMultisig = value;
        restart();
    }

    function setKeyHandle(uint32 handle) public {
        _keyHandle = handle;
        restart();
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}