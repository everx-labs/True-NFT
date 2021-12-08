pragma ton-solidity >= 0.52.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import '../DataChunk.sol';

contract DataChunkResolver {
    TvmCell _codeDataChunk;

    function resolveDataChunk(
        address addrData,
        uint128 chunkNumber
    ) public returns (address addrDataChunk) {
        TvmCell state = _buildDataChunkState(addrData, chunkNumber);
        uint256 hashState = tvm.hash(state);
        addrDataChunk = address.makeAddrStd(0, hashState);
    }

    function _buildDataChunkState(
        address addrData,
        uint128 chunkNumber
    ) internal virtual returns (TvmCell) {
        return tvm.buildStateInit({
            contr: DataChunk,
            varInit: {
                _code: _codeDataChunk,
                _addrData: addrData,
                _chunkNumber: chunkNumber
            },
            code: _codeDataChunk
        });
    }
}
