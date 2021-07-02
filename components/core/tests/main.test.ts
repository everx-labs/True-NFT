import { TonClient } from "@tonclient/core";
import { createClient } from "@ton-contracts/utils/client";
import TonContract from "@ton-contracts/utils/ton-contract";
import { callThroughMultisig } from "@ton-contracts/utils/net";
import pkgSafeMultisigWallet from "../ton-packages/SafeMultisigWallet.package";
import pkgNftRoot from "../ton-packages/NftRoot.package";
import pkgNftData from "../ton-packages/NftData.package";
import pkgNft from "../ton-packages/Nft.package";

describe("main test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcNftRoot: TonContract;
  let smcNft: TonContract;
  let smcNftData: TonContract;

  before(async () => {
    client = createClient();
    smcSafeMultisigWallet = new TonContract({
      client,
      name: "SafeMultisigWallet",
      tonPackage: pkgSafeMultisigWallet,
      address: process.env.MULTISIG_ADDRESS,
      keys: {
        public: process.env.MULTISIG_PUBKEY,
        secret: process.env.MULTISIG_SECRET,
      },
    });
  });

  it("deploy NftRoot", async () => {
    const keys = await client.crypto.generate_random_sign_keys();
    smcNftRoot = new TonContract({
      client,
      name: "NftRoot",
      tonPackage: pkgNftRoot,
      keys,
    });

    await smcNftRoot.calcAddress();

    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcNftRoot.address,
        value: 1_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    console.log(`NftRoot address: ${smcNftRoot.address}`);

    await smcNftRoot.deploy({
      input: {
        codeNft: (
          await client.boc.get_code_from_tvc({ tvc: pkgNft.image })
        ).code,
        codeNftData: (
          await client.boc.get_code_from_tvc({ tvc: pkgNftData.image })
        ).code,
      },
    });
  });

  it("deploy Nft", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgNftRoot.abi,
      functionName: "mintNft",
      input: {},
      dest: smcNftRoot.address,
      value: 1_000_000_000,
    });

    smcNftData = await getAddrNftData(
      client,
      smcNftRoot,
      smcSafeMultisigWallet
    );

    console.log(`NftData address: ${smcNftData.address}`);

    smcNft = new TonContract({
      client,
      name: "NftRoot",
      tonPackage: pkgNftRoot,
      address: (
        await smcNftRoot.run({
          functionName: "resolveNft",
          input: {
            addrRoot: smcNftRoot.address,
            addrNftData: smcNftData.address,
            addrOwner: smcSafeMultisigWallet.address,
          },
        })
      ).value.addrNft,
    });

    console.log(`Nft address: ${smcNft.address}`);
  });

  it("transfer ownership", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgNftRoot.abi,
      functionName: "transferOwnership",
      input: {
        addrNft: smcNft.address,
        addrNftData: smcNftData.address,
        addrTo:
          "0:0000000000000000000000000000000000000000000000000000000000001111",
      },
      dest: smcNftRoot.address,
      value: 1_000_000_000,
    });

    console.log(
      await smcNftData.run({
        functionName: "getOwner",
      })
    );
  });
});

const getAddrNftData = async (
  client: TonClient,
  smcNftRoot: TonContract,
  smcSafeMultisigWallet: TonContract
): Promise<TonContract> => {
  let smcNftData: TonContract;
  const { codeHashNftData } = (
    await smcNftRoot.run({
      functionName: "resolveCodeHashNftData",
      input: {},
    })
  ).value;

  const nftDatas = (
    await client.net.query_collection({
      collection: "accounts",
      filter: {
        code_hash: { eq: codeHashNftData.slice(2) },
      },
      result: "id",
    })
  ).result;

  const promises = nftDatas.map((el) => {
    const _smcNftData = new TonContract({
      client,
      name: "",
      tonPackage: pkgNftData,
      address: el.id,
    });
    return _smcNftData.run({
      functionName: "getOwner",
    });
  });

  const results = await Promise.all(promises);

  results.forEach((el: any, i) => {
    if (el.value.addrOwner === smcSafeMultisigWallet.address) {
      smcNftData = new TonContract({
        client,
        name: "NftData",
        tonPackage: pkgNftData,
        address: nftDatas[i].id,
      });
    }
  });

  return smcNftData;
};
