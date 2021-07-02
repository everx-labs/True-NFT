import { TonClient } from "@tonclient/core";
import pkgNft from "../ton-packages/Nft.package";
import pkgNftData from "../ton-packages/NftData.package";
import pkgNftRoot from "../ton-packages/NftRoot.package";
import pkgNftBasis from "../ton-packages/NftBasis.package";
import pkgSafeMultisigWallet from "../../../ton-packages/SetCodeMultisig.package";
import TonContract from "@ton-contracts/utils/ton-contract";
import { createClient } from "@ton-contracts/utils/client";
import {
  base64ToHex,
  hexToBase64,
  utf8ToHex,
} from "@ton-contracts/utils/convert";
import { callThroughMultisig } from "@ton-contracts/utils/net";
const fs = require("fs");

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
    console.log(process.env.MULTISIG_ADDRESS);
  });

  it("deploy NftRoot", async () => {
    const keys = await client.crypto.generate_random_sign_keys();
    smcNftRoot = new TonContract({
      client,
      name: "NftRoot",
      tonPackage: pkgNftRoot,
      keys,
    });

    await smcNftRoot.calcAddress({
      initialData: {
        _addrOwner: smcSafeMultisigWallet.address,
      },
    });

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
        name: utf8ToHex("name"),
        description: utf8ToHex("desc"),
        tokenCode: utf8ToHex("CodeToken"),
        totalSupply: 640,
      },
      initialData: {
        _addrOwner: smcSafeMultisigWallet.address,
      },
    });
  });

  it("deploy Basis and Nft", async () => {

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgNftRoot.abi,
      functionName: "deployBasis",
      input: {
        codeBasis: (await client.boc.get_code_from_tvc({ tvc: pkgNftBasis.image })).code
      },
      dest: smcNftRoot.address,
      value: 1_000_000_000,
    });

    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgNftRoot.abi,
      functionName: "mintNft",
      input: {
        creationDate: 1624276234,
        comment: utf8ToHex("comment")
      },
      dest: smcNftRoot.address,
      value: 1_000_000_000,
    });
  });

  it("get all roots", async () => {

    let nftBasises = [];
    let counter = 0;

    while (nftBasises.length === 0 && counter <= 500) {
      const qwe = await client.net.query_collection({
        collection: "accounts",
        filter: {
          code_hash: { eq: process.env.BASIS_CODEHASH },
        },
        result: "id",
      });
      counter++;
      nftBasises = qwe.result;
    }

    const promises = nftBasises.map((el) => {
      const _smcNftBasis = new TonContract({
        client,
        name: "",
        tonPackage: pkgNftBasis,
        address: el.id,
      });
      return _smcNftBasis.run({
        functionName: "getInfo",
      });
    });

    const results = await Promise.all(promises);

    results.forEach((el: any, i) => {
      //TODO ...
      // console.log(el, i);
      
    });
  });

  it("get my nfts", async () => {

    const { codeHashNft } = (
      await smcNftRoot.run({
        functionName: "resolveCodeHashNft",
        input: {addrOwner: process.env.MULTISIG_ADDRESS},
      })
    ).value;
    console.log(codeHashNft);
    
    

    let nfts = [];
    let counter = 0;

    while (nfts.length === 0 && counter <= 500) {
      const qwe = await client.net.query_collection({
        collection: "accounts",
        filter: {
          code_hash: { eq: codeHashNft.slice(2) },
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
        tonPackage: pkgNft,
        address: el.id,
      });
      return _smcNft.run({
        functionName: "getInfo",
      });
    });

    const results = await Promise.all(promises);

    results.forEach((el: any, i) => {
      //TODO ...
      console.log(el, i);
    });
  });

  it("get Nft", async () => {
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

  it("set data", async () => {
    const bitmap = fs.readFileSync("./tests/surfer.jpg");
    const strData = new Buffer(bitmap).toString("base64");

    const length = 15000;
    const pattern = new RegExp(".{1," + length + "}", "g");
    let res = strData.match(pattern);

    const promises = res.map(async (el, index) => {
      await callThroughMultisig({
        client,
        smcSafeMultisigWallet,
        abi: pkgNftData.abi,
        functionName: "setNftDataContent",
        input: {
          index: index,
          part: base64ToHex(el),
        },
        dest: smcNftData.address,
        value: 400_000_000,
      });
      console.log(0, index);
    });

    await Promise.all(promises);
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

  it("get part of data", async () => {
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

    const promises = nftDatas.map(async (el) => {
      const _smcNftData = new TonContract({
        client,
        name: "",
        tonPackage: pkgNftData,
        address: el.id,
      });
      return await _smcNftData.run({
        functionName: "getInfo",
      });
    });
    const results = await Promise.all(promises);

    const _smcNftData = new TonContract({
      client,
      name: "",
      tonPackage: pkgNftData,
      address: smcNftData.address,
    });
    const res = await _smcNftData.run({
      functionName: "getInfo",
    });

    let str = "";
    for (var key in res.value.content) {
      str += res.value.content[key];
    }

    const pictBuff = hexToBase64(str);

    fs.writeFileSync(`./pictBuff.jpg`, pictBuff, "base64");
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

    let nftDatas = [];
    let counter = 0;

    while (nftDatas.length === 0 && counter <= 500) {
      const ad = await client.net.query_collection({
        collection: "accounts",
        filter: {
          code_hash: { eq: codeHashNftData.slice(2) },
        },
        result: "id",
      });
      counter++;
      nftDatas = ad.result;
      // console.log(0, counter);
      // console.log(0, nftDatas);
    }

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
});
