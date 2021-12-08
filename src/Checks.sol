pragma ton-solidity >= 0.52.0;

contract Checks {
    uint8 _checkList;

    function _passCheck(uint8 check) internal inline {
        _checkList &= ~check;
    }
    function _isCheckListEmpty() internal view inline returns (bool) {
        return (_checkList == 0);
    }
}
