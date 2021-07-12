pragma ton-solidity >= 0.43.0;

interface IIndex {
    function destruct() external;
    function getInfo() external view returns (
        address addrRoot,
        address addrOwner,
        address addrData
    );
}
