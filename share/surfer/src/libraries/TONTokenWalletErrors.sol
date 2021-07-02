pragma ton-solidity >= 0.39.0;

library TONTokenWalletErrors {
    uint8 constant error_message_sender_is_not_my_owner            = 100;
    uint8 constant error_not_enough_balance                        = 101;
    uint8 constant error_message_sender_is_not_my_root             = 102;
    uint8 constant error_message_sender_is_not_good_wallet         = 103;
    uint8 constant error_wrong_spender                             = 104;
    uint8 constant error_not_enough_allowance                      = 105;
    uint8 constant error_wrong_recipient                           = 106;
    uint8 constant error_wrong_value_of_tokens                     = 107;
    uint8 constant error_already_sended                            = 108;
    uint8 constant error_not_enough_grams                          = 109;
}
