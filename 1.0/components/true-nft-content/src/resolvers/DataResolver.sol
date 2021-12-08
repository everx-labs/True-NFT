pragma ton-solidity >= 0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import '../Data.sol';

contract DataResolver {
    TvmCell _codeData;

    function resolveCodeHashData() public view returns (uint256 codeHashData) {
        return tvm.hash(_buildDataCode(address(this)));
    }

    function resolveData(
        address addrRoot,
        uint256 id
    ) public view returns (address addrData) {
        TvmCell code = _buildDataCode(addrRoot);
        TvmCell state = _buildDataState(code, id);
        uint256 hashState = tvm.hash(state);
        addrData = address.makeAddrStd(0, hashState);
    }

    function _buildDataCode(address addrRoot) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        return tvm.setCodeSalt(_codeData, salt.toCell());
    }

    function _buildDataState(
        TvmCell code,
        uint256 id
    ) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Data,
            varInit: {_id: id},
            code: code
        });
    }
}