pragma ton-solidity >= 0.39.0;

library RootTokenContractErrors {
    uint8 constant error_message_sender_is_not_my_owner = 100;
    uint8 constant error_not_enough_grams = 101;
    uint8 constant error_wrong_recipient = 102;
    uint8 constant error_total_granted_too_much = 103;
    uint8 constant error_already_granted = 104;
}
