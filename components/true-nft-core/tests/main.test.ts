import { TonClient } from "@tonclient/core";
import { createClient } from "@ton-contracts/utils/client";
import TonContract from "@ton-contracts/utils/ton-contract";
import { callThroughMultisig } from "@ton-contracts/utils/net";
import pkgSafeMultisigWallet from "../../../ton-packages/SetCodeMultisig.package"
import pkgNftRoot from "../ton-packages/NftRoot.package";
import pkgData from "../ton-packages/Data.package";
import pkgIndex from "../ton-packages/Index.package";
import { expect } from "chai";

describe("main test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcNftRoot: TonContract;
  let smcNftRoot2: TonContract;
  let smcNft: TonContract;
  let smcData: TonContract;
  let myDeployedNft = 0;
  let myNftRootAll = 0;
  let zeroAddress = '0:0000000000000000000000000000000000000000000000000000000000000000';
  let fakeAddress = "0:0000000000000000000000000000000000000000000000000000000000001111";

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

  it("deploy first NftRoot", async () => {
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
        value: 10_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    console.log(`NftRoot address: ${smcNftRoot.address}`);

    await smcNftRoot.deploy({
      input: {
        codeIndex: (
          await client.boc.get_code_from_tvc({ tvc: pkgIndex.image })
        ).code,
        codeData: (
          await client.boc.get_code_from_tvc({ tvc: pkgData.image })
        ).code,
      },
    });

    const res = (
      await client.net.query_collection({
        collection: "accounts",
        filter: {
          id: { eq: smcNftRoot.address },
        },
        result: "acc_type",
      })
    ).result[0];

    expect(1).to.be.equal(res.acc_type);
  });

  it("deploy Nft from first root", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgNftRoot.abi,
      functionName: "mintNft",
      input: {},
      dest: smcNftRoot.address,
      value: 1_500_000_000,
    });

    smcData = await getAddrData(
      client,
      smcNftRoot,
      smcSafeMultisigWallet
    );

    console.log(`Data address: ${smcData.address}`);

    const res = await smcData.run({
      functionName: "getInfo"
    });
    myDeployedNft++;
    
    expect(smcNftRoot.address).to.be.equal(res.value.addrRoot);
    expect(process.env.MULTISIG_ADDRESS).to.be.equal(res.value.addrOwner);
  });

  it("get my nft inside root before transfer", async () => {
    const results = await getMyNfts(client, smcData, smcNftRoot.address);
    expect(1).to.be.equal(results.length);
  });

   it("get myAll nft", async () => {
     // At this point, the test may break 
    const results = await getMyNfts(client, smcData, zeroAddress);
    myNftRootAll = results.length;
    expect(myDeployedNft).to.be.equal(results.length);
  });

  it("transfer ownership", async () => {
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgData.abi,
      functionName: "transferOwnership",
      input: {
        addrTo:fakeAddress
      },
      dest: smcData.address,
      value: 1_000_000_000,
    });

    const res = await smcData.run({
      functionName: "getOwner",
    });

    expect(fakeAddress).to.be.equal(res.value.addrOwner);
  });

  it("get my nft inside root after transfer", async () => {
    const results = await getMyNfts(client, smcData, smcNftRoot.address);
    expect(0).to.be.equal(results.length);
  });

   it("get myAll nft after transfer", async () => {
    const results = await getMyNfts(client, smcData, zeroAddress);
    expect(myNftRootAll-1).to.be.equal(results.length);
  });
});

const getAddrData = async (
  client: TonClient,
  smcNftRoot: TonContract,
  smcSafeMultisigWallet: TonContract
): Promise<TonContract> => {
  let smcData: TonContract;
  const { codeHashData } = (
    await smcNftRoot.run({
      functionName: "resolveCodeHashData",
      input: {},
    })
  ).value;
  
  const Datas = (
    await client.net.query_collection({
      collection: "accounts",
      filter: {
        code_hash: { eq: codeHashData.slice(2) },
      },
      result: "id",
    })
  ).result;

  const promises = Datas.map((el) => {
    const _smcData = new TonContract({
      client,
      name: "",
      tonPackage: pkgData,
      address: el.id,
    });
    return _smcData.run({
      functionName: "getOwner",
    });
  });

  const results = await Promise.all(promises);

  results.forEach((el: any, i) => {
    if (el.value.addrOwner === smcSafeMultisigWallet.address) {
      smcData = new TonContract({
        client,
        name: "Data",
        tonPackage: pkgData,
        address: Datas[i].id,
      });
    }
  });

  return smcData;
};

const getMyNfts = async (
  client: TonClient,
  smcData: TonContract,
  rootAddr: string
): Promise<any> => {
  const { codeHashIndex } = (
    await smcData.run({
      functionName: "resolveCodeHashIndex",
      input: {
        addrRoot: rootAddr,
        addrOwner: process.env.MULTISIG_ADDRESS
      },
    })
  ).value;

  let nfts = [];
  let counter = 0;

  while (nfts.length === 0 && counter <= 500) {
    const qwe = await client.net.query_collection({
      collection: "accounts",
      filter: {
        code_hash: { eq: codeHashIndex.slice(2) },
      },
      result: "id",
    });
    counter++;
    nfts = qwe.result;
  }

  const promises = nfts.map((el) => {
    const _smcNft = new TonContract({
      client,
      name: "",
      tonPackage: pkgIndex,
      address: el.id,
    });
    return _smcNft.run({
      functionName: "getInfo",
    });
  });

  return await Promise.all(promises);
};
