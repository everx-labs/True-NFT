import { TonClient } from "@tonclient/core";
import pkgIndex from "../ton-packages/Index.package";
import pkgData from "../ton-packages/Data.package";
import pkgNftRoot from "../ton-packages/NftRoot.package";
import pkgIndexBasis from "../ton-packages/IndexBasis.package";
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
  let smcIndex: TonContract;
  let smcData: TonContract;
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
        value: 10_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    console.log(`NftRoot address: ${smcNftRoot.address}`);

    /* -------------------------------------------------------------------------- */
    /*                                 ANCHOR zxc                                 */
    /* -------------------------------------------------------------------------- */


    const bitmap = fs.readFileSync("./tests/surfer.jpg");
    const strData = Buffer.from(bitmap).toString("base64");

    const length = 15000;
    const pattern = new RegExp(".{1," + length + "}", "g");
    let res = strData.match(pattern);

    const promises = res.map(async (el, index) => {
      await smcNftRoot.deploy({
        input: {
          codeIndex: (
            await client.boc.get_code_from_tvc({ tvc: pkgIndex.image })
          ).code,
          codeData: (
            await client.boc.get_code_from_tvc({ tvc: pkgData.image })
          ).code,
          name: utf8ToHex("name"),
          description: utf8ToHex("desc"),
          tokenCode: utf8ToHex("CodeToken"),
          totalSupply: 640,
          index: index,
          part: base64ToHex(el),
        },
        initialData: {
          _addrOwner: smcSafeMultisigWallet.address,
        },
      });
    });

    await Promise.all(promises);
  });

  it("deploy Basis and Nft", async () => {

    // await callThroughMultisig({
    //   client,
    //   smcSafeMultisigWallet,
    //   abi: pkgNftRoot.abi,
    //   functionName: "deployBasis",
    //   input: {
    //     codeIndexBasis: (await client.boc.get_code_from_tvc({ tvc: pkgIndexBasis.image })).code
    //   },
    //   dest: smcNftRoot.address,
    //   value: 1_000_000_000,
    // });
    
    await callThroughMultisig({
      client,
      smcSafeMultisigWallet,
      abi: pkgNftRoot.abi,
      functionName: "mintNft",
      input: {
        creationDate: 1624276234,
        comment: utf8ToHex("comment"),
        owner: process.env.MULTISIG_ADDRESS
      },
      dest: smcNftRoot.address,
      value: 2_000_000_000,
    });
  });

  // it("get all roots", async () => {

  //   let nftBasises = [];
  //   let counter = 0;

  //   while (nftBasises.length === 0 && counter <= 500) {
  //     const qwe = await client.net.query_collection({
  //       collection: "accounts",
  //       filter: {
  //         code_hash: { eq: process.env.BASIS_CODEHASH },
  //       },
  //       result: "id",
  //     });
  //     counter++;
  //     nftBasises = qwe.result;
  //   }

  //   const promises = nftBasises.map((el) => {
  //     const _smcNftBasis = new TonContract({
  //       client,
  //       name: "",
  //       tonPackage: pkgIndexBasis,
  //       address: el.id,
  //     });
  //     return _smcNftBasis.run({
  //       functionName: "getInfo",
  //     });
  //   });

  //   const results = await Promise.all(promises);

  //   results.forEach((el: any, i) => {
  //     //TODO ...
  //     // console.log(el, i);
      
  //   });
  // });

  it("get my nfts", async () => {
    smcData = await getAddrNftData(
      client,
      smcNftRoot,
      smcSafeMultisigWallet
    );

    const results = await getMyNfts(client, smcData, zeroAddress);
    results.forEach((el: any, i) => {
      //TODO ...
      console.log(el, i);
    });
  });

  /* -------------------------------------------------------------------------- */
  /*                                 ANCHOR zxc                                 */
  /* -------------------------------------------------------------------------- */
  // it("set data", async () => {
  //   const bitmap = fs.readFileSync("./tests/surfer.jpg");
  //   const strData = Buffer.from(bitmap).toString("base64");

  //   const length = 15000;
  //   const pattern = new RegExp(".{1," + length + "}", "g");
  //   let res = strData.match(pattern);

  //   const promises = res.map(async (el, index) => {
  //     await callThroughMultisig({
  //       client,
  //       smcSafeMultisigWallet,
  //       abi: pkgData.abi,
  //       functionName: "setNftDataContent",
  //       input: {
  //         index: index,
  //         part: base64ToHex(el),
  //       },
  //       dest: smcData.address,
  //       value: 400_000_000,
  //     });
  //   });

  //   await Promise.all(promises);
  // });

  // it("transfer ownership", async () => {
  //   await callThroughMultisig({
  //     client,
  //     smcSafeMultisigWallet,
  //     abi: pkgData.abi,
  //     functionName: "transferOwnership",
  //     input: {
  //       addrTo:
  //         "0:0000000000000000000000000000000000000000000000000000000000001111",
  //     },
  //     dest: smcData.address,
  //     value: 1_000_000_000,
  //   });

  //   console.log(
  //     await smcData.run({
  //       functionName: "getOwner",
  //     })
  //   );
  // });

  it("get part of data", async () => {
    const { codeHashData } = (
      await smcNftRoot.run({
        functionName: "resolveCodeHashData",
        input: {},
      })
    ).value;

    const nftDatas = (
      await client.net.query_collection({
        collection: "accounts",
        filter: {
          code_hash: { eq: codeHashData.slice(2) },
        },
        result: "id",
      })
    ).result;

    const promises = nftDatas.map(async (el) => {
      const _smcNftData = new TonContract({
        client,
        name: "",
        tonPackage: pkgData,
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
      tonPackage: pkgData,
      address: smcData.address,
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
    
    let smcData: TonContract;
    const { codeHashData } = (
      await smcNftRoot.run({
        functionName: "resolveCodeHashData",
        input: {},
      })
    ).value;

    let nftDatas = [];
    let counter = 0;

    while (nftDatas.length === 0 && counter <= 500) {
      const ad = await client.net.query_collection({
        collection: "accounts",
        filter: {
          code_hash: { eq: codeHashData.slice(2) },
        },
        result: "id",
      });
      counter++;
      nftDatas = ad.result;
    }

    const promises = nftDatas.map((el) => {
      const _smcNftData = new TonContract({
        client,
        name: "",
        tonPackage: pkgData,
        address: el.id,
      });
      return _smcNftData.run({
        functionName: "getOwner",
      });
    });

    const results = await Promise.all(promises);

    results.forEach((el: any, i) => {
      if (el.value.addrOwner === smcSafeMultisigWallet.address) {
        smcData = new TonContract({
          client,
          name: "NftData",
          tonPackage: pkgData,
          address: nftDatas[i].id,
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
});

