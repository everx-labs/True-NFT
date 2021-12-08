pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;


import "./NftRoot.sol";

import './libraries/Constants.sol';
import './libraries/Errors.sol';

contract Manager {

    TvmCell _rootCode;

    constructor (TvmCell rootCode) public {
        tvm.accept();
        _rootCode = rootCode;
    }

    function deployRoot(
        address addrOwner,
        TvmCell codeIndex,
        TvmCell codeData,
        string name,
        string description,
        string tokenCode,
        uint256 totalSupply,
        uint128 index,
        bytes part
    ) public view {
        tvm.accept();

        TvmCell stateNftRoot = _buildNftRootState(addrOwner);
        new NftRoot {stateInit: stateNftRoot, value: Constants.DEPLOY_INDEX_FEE}( codeIndex, codeData, name, description, tokenCode, totalSupply, index, part);
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