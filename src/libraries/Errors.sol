pragma ton-solidity >= 0.52.0;

library Errors {
    uint16 constant INVALID_CALLER = 100;
    uint16 constant INVALID_VALUE = 101;
    uint16 constant INVALID_CALLER_OR_VALUE = 102;
    uint16 constant INVALID_ARGUMENTS = 103;
    uint16 constant CONTRACT_NOT_INITED = 104;
    uint16 constant CONTRACT_ALLREADY_INITED = 105;
    uint16 constant CONTRACT_CODE_NOT_SALTED = 106;
    uint16 constant CONTRACT_IS_NOT_ON_SALE = 107;
    uint16 constant CONTRACT_IS_ON_SALE = 108;
    uint16 constant ROYALTY_ALREADY_SET = 108;
}
