pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import '../NftData.sol';

contract NftDataResolver {
    TvmCell _codeNftData;


    function resolveCodeHashNftData() public view returns (uint256 codeHashNftData) {
        return tvm.hash(_buildNftDataCode(address(this)));
    }

    function resolveNftData(address addrRoot, uint256 id) public view returns (address addrNftData) {
        TvmCell code = _buildNftDataCode(addrRoot);
        TvmCell state = _buildNftDataState(code, id);
        uint256 hashState = tvm.hash(state);
        addrNftData = address.makeAddrStd(0, hashState);
    }

    function _buildNftDataCode(address addrRoot) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeNftData, salt.toCell());
    }

    function _buildNftDataState(TvmCell code, uint256 id) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: NftData,
            varInit: {_id: id},
            code: code
        });
    }
}