pragma ton-solidity >=0.43.0;

pragma AbiHeader expire;
pragma AbiHeader time;

import './interfaces/INftData.sol';

contract NftData is INftData {
    address _addrRoot;
    address _addrOwner;
    address _addrAuthor;
    uint256 static _id;

    string _name;
    string _description;
    string _tokenCode;
    uint64 _creationDate;
    string _comment;

    // index => part of image
    mapping(uint128 => bytes) _content;

    constructor(
        address addrOwner,
        address addrAuthor,
        string name,
        string description,
        string tokenCode,
        uint64 creationDate,
        string comment
    ) public {
        optional(TvmCell) optSalt = tvm.codeSalt(tvm.code());
        require(optSalt.hasValue(), 102);
        (address addrRoot) = optSalt.get().toSlice().decode(address);
        require(msg.sender == addrRoot, 100);
        tvm.accept();
        _addrRoot = addrRoot;
        _addrOwner = addrOwner;
        _addrAuthor = addrAuthor;
        _name = name;
        _description = description;
        _tokenCode = tokenCode;
        _creationDate = creationDate;
        _comment = comment;
    }

    function setOwner(address addrOwner) public override {
        require(msg.sender == _addrRoot, 100);
        _addrOwner = addrOwner;
    }

    function setNftDataContent(uint128 index, bytes part) public {
        require(msg.sender == _addrOwner, 100);
        tvm.accept();
        _content[index] = part;
        msg.sender.transfer({value: 0, flag: 64, bounce: false});
    }

    function getOwner() public view returns(address addrOwner, address addrNftData) {
        addrOwner = _addrOwner;
        addrNftData = address(this);
    }

    function getInfo() public view
    returns(
        mapping(uint128 => bytes) content,
        address author,
        string name,
        string description,
        string tokenCode,
        uint64 creationDate,
        string comment
    ) {
        tvm.accept();
        content = _content;
        author = _addrAuthor;
        name = _name;
        description = _description;
        tokenCode = _tokenCode;
        creationDate = _creationDate;
        comment = _comment;
    }

    function destruct(address recipient) public {
        require(msg.sender == _addrRoot, 100);

        recipient.transfer(0, false, 64);
        selfdestruct(recipient);
    }

}
