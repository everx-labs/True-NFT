pragma ton-solidity >= 0.43.0;

interface IData {
    function getOwner() external view returns (address addrOwner, address addrNftData);
    function getInfo() external view returns (
        mapping(uint128 => bytes) content,
        address author,
        string name,
        string description,
        string tokenCode,
        uint64 creationDate,
        string comment
    );
}
