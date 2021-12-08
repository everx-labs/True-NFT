import tonos_ts4.ts4 as ts4

ts4.init("../build/", verbose=False)


def cb_false(_):
    return False


def call_with_wallet(smc_wallet, dest, value, payload, flags=3, bounce=True):
    smc_wallet.call_method(
        "sendTransaction",
        {
            "dest": dest,
            "value": value,
            "bounce": bounce,
            "flags": flags,
            "payload": payload,
        },
        keys_multisig[0],
    )


def init_smc_nft_root(owner, mintType=0, fee=0):
    smc = ts4.BaseContract(
        "NftRootCustomMint",
        {
            "mintType": mintType,
            "fee": fee,
            "name": "name",
            "descriprion": "descriprion",
            "icon": "",
            "addrAuthor": owner,
        },
        initial_data={"_addrOwner": owner},
    )
    code_index = ts4.load_code_cell("Index")
    code_index_basis = ts4.load_code_cell("IndexBasis")
    code_data = ts4.load_code_cell("Data")
    code_data_chunk = ts4.load_code_cell("DataChunk")

    def setCode(method, code):
        call_with_wallet(
            smc_wallet,
            smc.address,
            2 * 10 ** 8,
            ts4.encode_message_body(
                "NftRootCustomMint",
                method,
                {"code": code},
            ),
        )
        ts4.dispatch_messages()

    setCode("setCodeIndex", code_index)
    setCode("setCodeIndexBasis", code_index_basis)
    setCode("setCodeData", code_data)
    setCode("setCodeDataChunk", code_data_chunk)

    assert smc.call_getter("_inited", {}) == True, "Contract hasn't been inited yet"

    return smc


keys_multisig = ts4.make_keypair()
smc_wallet = ts4.BaseContract(
    "SurfMultisigWallet",
    {"owners": [keys_multisig[1]], "reqConfirms": 1},
    keypair=keys_multisig,
)
smc_wallet_random = ts4.BaseContract(
    "SurfMultisigWallet",
    {"owners": [keys_multisig[1]], "reqConfirms": 1},
    keypair=keys_multisig,
)

# Test only owner minting

smc_nft_root = init_smc_nft_root(smc_wallet.address, 0, 0)


def mint(smc_wallet, value=3 * 10 ** 9):
    call_with_wallet(
        smc_wallet,
        smc_nft_root.address,
        value,
        ts4.encode_message_body(
            "NftRootCustomMint",
            "mintNft",
            {
                "wid": 0,
                "name": "test",
                "descriprion": "descriprion",
                "contentHash": 0,
                "mimeType": "none",
                "chunks": 0,
                "chunkSize": 0,
                "size": 0,
                "meta": {
                    "height": 0,
                    "width": 0,
                    "duration": 0,
                    "extra": "",
                    "json": "",
                },
            },
        ),
    )


mint(smc_wallet)
ts4.dispatch_one_message()
ts4.dispatch_messages()
mint(smc_wallet_random)
ts4.dispatch_one_message(100)
ts4.dispatch_messages(cb_false)
mint(smc_wallet_random, 8 * 10 ** 9)
ts4.dispatch_one_message(100)
ts4.dispatch_messages()


# Test only fee minting

smc_nft_root = init_smc_nft_root(smc_wallet.address, 1, 5 * 10 ** 9)

mint(smc_wallet)
ts4.dispatch_one_message(100)
ts4.dispatch_messages(cb_false)
mint(smc_wallet_random)
ts4.dispatch_one_message(101)
ts4.dispatch_messages(cb_false)
mint(smc_wallet_random, 8 * 10 ** 9)
ts4.dispatch_one_message()
ts4.dispatch_messages()

# Test fee and owner minting

smc_nft_root = init_smc_nft_root(smc_wallet.address, 2, 5 * 10 ** 9)

mint(smc_wallet)
ts4.dispatch_one_message()
ts4.dispatch_messages()
mint(smc_wallet_random)
ts4.dispatch_one_message(102)
ts4.dispatch_messages(cb_false)
mint(smc_wallet_random, 8 * 10 ** 9)
ts4.dispatch_one_message()
ts4.dispatch_messages()

# Test all minting

smc_nft_root = init_smc_nft_root(smc_wallet.address, 2)

mint(smc_wallet)
ts4.dispatch_one_message()
ts4.dispatch_messages()
mint(smc_wallet_random)
ts4.dispatch_one_message()
ts4.dispatch_messages()

print("complete!")
