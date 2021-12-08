pragma ton-solidity >= 0.43.0;

interface IData {
    function onFillComplete() external;
    function transferOwnership(address addrTo) external;

    function getInfo() external view returns (
        address addrRoot,
        address addrOwner,
        address addrData,
        address addrStorage
    );
    function getOwner() external view returns (address addrOwner);
}
