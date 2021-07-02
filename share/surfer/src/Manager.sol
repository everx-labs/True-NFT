pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;


import "./NftRoot.sol";


contract Manager {

    TvmCell _rootCode;

    constructor (TvmCell rootCode) public {
        tvm.accept();
        _rootCode = rootCode;
    }

    function deployRoot(
        address addrOwner,
        TvmCell codeNft,
        TvmCell codeNftData,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply
    ) public view {
        tvm.accept();

        TvmCell stateNftRoot = _buildNftRootState(addrOwner);
        new NftRoot {stateInit: stateNftRoot, value: 0.4 ton}( codeNft, codeNftData, name, description, tokenCode, totalSupply);
    }

    function _buildNftRootState( address addrOwner) internal virtual view returns (TvmCell) {
        TvmCell code = _rootCode.toSlice().loadRef();
        return tvm.buildStateInit({
            contr: NftRoot,
            varInit: {_addrOwner: addrOwner},
            code: code
        });
    }
}