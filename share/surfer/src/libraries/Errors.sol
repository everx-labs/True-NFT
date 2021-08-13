pragma ton-solidity >= 0.43.0;

library Errors {
    uint128 constant ERROR_MESSAGE_SENDER_IS_NOT_OWNER = 100;
    uint128 constant ERROR_MESSAGE_SENDER_IS_NOT_ROOT = 101;
    uint128 constant ERROR_MINTED_TOO_MUCH = 102;
    uint128 constant ERROR_NOT_ENOUGH_GRAMS = 103;
    uint128 constant ERROR_EMPTY_SALT = 104;
    uint128 constant ERROR_MSG_VALUE_LESS_THAN_PRICE = 105;
}