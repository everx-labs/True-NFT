pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './resolvers/IndexResolver.sol';

import './interfaces/IData.sol';
import './interfaces/IStorage.sol';

import './libraries/Constants.sol';


contract Storage is IStorage {
    address static _addrData;

    address _addrRoot;
    address _addrAuthor;
    uint8 _chunks;
    string _mimeType;
    mapping(uint8 => bytes) _content;
    bool public _complete;

    constructor(uint8 chunks, string mimeType) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 101);
        (address addrRoot, address addrAuthor) = optSalt.get().toSlice().decode(address, address);
        require(msg.sender == addrRoot);
        require(msg.value >= Constants.MIN_FOR_DEPLOY);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrAuthor = addrAuthor;
        _chunks = chunks;
        _mimeType = mimeType;
    }

    function fillContent(uint8 chankNumber, bytes part) public override {
        require(_complete == false, 105);
        require(msg.sender == _addrAuthor, 106);
        _content[chankNumber] = part;

        uint8 acc;

        optional(uint8, bytes) chunk = _content.min();
        while (chunk.hasValue()) {
            (uint8 currentNumber, bytes currentPart) = chunk.get();
            acc++;
            chunk = _content.next(currentNumber);
        }
        if (acc == _chunks) {
            IData(_addrData).onFillComplete{
                value: 0,
                bounce: true,
                flag: 64
            }();

            _complete = true;
        } else {
          msg.sender.transfer(0, true, 64);  
        }
    }

    function getInfo() public view override returns (
        address addrData,
        address addrRoot,
        address addrAuthor,
        string mimeType,
        mapping(uint8 => bytes) content
    ) {
        addrData = _addrData;
        addrRoot = _addrRoot;
        addrAuthor = _addrAuthor;
        mimeType = _mimeType;
        content = _content;
    }
}