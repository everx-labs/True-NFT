pragma ton-solidity >= 0.52.0;

pragma AbiHeader expire;
pragma AbiHeader time;


import './interfaces/IDataChunk.sol';

import './libraries/Constants.sol';


contract DataChunk is IDataChunk {

    TvmCell static _code;
    address static _addrData;
    uint128 static _chunkNumber;

    bytes _chunk;

    constructor(bytes chunk) public {
        require(msg.sender == _addrData);
        tvm.accept();

        _chunk = chunk;
    }

    function getInfo() public view override returns (
        address addrData,
        uint128 chunkNumber,
        bytes chunk
    ) {
        addrData = _addrData;
        chunkNumber = _chunkNumber;
        chunk = _chunk;
    }
}
