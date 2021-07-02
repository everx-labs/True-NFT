pragma ton-solidity >= 0.43.0;
pragma AbiHeader expire;
pragma AbiHeader time;

import '../Nft.sol';

contract NftResolver {
    TvmCell _codeNft;

    function resolveNft(address addrRoot, address addrNftData, address addrOwner) public view returns (address addrNft) {
        TvmCell code = _buildNftCode(addrRoot, addrOwner);
        TvmCell state = _buildNftState(code, addrNftData);
        uint256 hashState = tvm.hash(state);
        addrNft = address.makeAddrStd(0, hashState);
    }

    function _buildNftCode(address addrRoot, address addrOwner) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(addrRoot);
        salt.store(addrOwner);
        return tvm.setCodeSalt(_codeNft, salt.toCell());
    }

    function _buildNftState(TvmCell code, address addrNftData) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Nft,
            varInit: {_addrNftData: addrNftData},
            code: code
        });
    }
}