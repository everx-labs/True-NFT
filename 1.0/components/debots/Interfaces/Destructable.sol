pragma ton-solidity >=0.35.0;

abstract contract Destructable {
    function _destruct(address addr) internal {
        selfdestruct(addr);
    }

    function destruct() public virtual;
}