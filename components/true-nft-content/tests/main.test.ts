import { KeyPair, TonClient } from "@tonclient/core";
import pkgIndex from "../ton-packages/Index.package";
import pkgData from "../ton-packages/Data.package";
import pkgStorage from "../ton-packages/Storage.package";
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
import { expect } from "chai";
const fs = require("fs");

describe("main test", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcNftRoot: TonContract;
  let smcData: TonContract;
  let smcStorage: TonContract;
  let keys: KeyPair;
  let wid = 0;
  let complete: any;

  const bitmap = fs.readFileSync("./tests/test.jpg");
  const strData = Buffer.from(bitmap).toString("base64");

  const length = 15000;
  const pattern = new RegExp(".{1," + length + "}", "g");
  let res = strData.match(pattern);

  let mimeType = utf8ToHex("png");

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
    keys = await client.crypto.generate_random_sign_keys();
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
        value: 5_000_000_000,
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
        codeStorage: (
          await client.boc.get_code_from_tvc({ tvc: pkgStorage.image })
        ).code,
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
        codeIndexBasis: (await client.boc.get_code_from_tvc({ tvc: pkgIndexBasis.image })).code
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
        wid,
        chunks: res.length,
        mimeType
      },
      dest: smcNftRoot.address,
      value: 5_000_000_000,
    });
  });

  it("get data and storage", async () => {
    const addrData = await smcNftRoot.run({
      functionName: "resolveData",
      input: {
        addrRoot: smcNftRoot.address,
        id: 0
      },
    })
    console.log('data', addrData.value.addrData);

    smcData = new TonContract({
      client,
      name: "Data",
      tonPackage: pkgData,
      keys,
      address: addrData.value.addrData
    });

    let addrStorage = await smcNftRoot.run({
      functionName: "resolveStorage",
      input: {
        addrRoot: smcNftRoot.address,
        addrData: smcData.address,
        addrAuthor: smcSafeMultisigWallet.address
      },
    })
    console.log('storage', addrStorage.value.addrStorage);

    addrStorage = `${wid}:${addrStorage.value.addrStorage.slice(2)}`


    smcStorage = new TonContract({
      client,
      name: "Storage",
      tonPackage: pkgStorage,
      keys,
      address: addrStorage
    });

    complete = await smcStorage.run({
      functionName: "_complete",
    })
    console.log('Complete: ', complete.value._complete);
  })

  it("Checking the completeness of contract fields", async () => {
    let res = await smcData.run({
      functionName: "getInfo"
    })
    expect(res.value.addrRoot).to.be.equal(smcNftRoot.address)
    expect(res.value.addrOwner).to.be.equal(smcSafeMultisigWallet.address)
    expect(res.value.addrData).to.be.equal(smcData.address)
    expect(res.value.addrStorage).to.be.equal(smcStorage.address)

    res = await smcStorage.run({
      functionName: "getInfo"
    })
    expect(res.value.addrRoot).to.be.equal(smcNftRoot.address)
    expect(res.value.addrAuthor).to.be.equal(smcSafeMultisigWallet.address)
    expect(res.value.addrData).to.be.equal(smcData.address)
    expect(res.value.mimeType).to.be.equal(mimeType)

    res = await smcNftRoot.run({
      functionName: "getInfo"
    })
    expect(res.value.totalMinted).to.be.equal('0x0000000000000000000000000000000000000000000000000000000000000001')

    res = await smcNftRoot.run({
      functionName: "_addrBasis"
    })
    expect(res.value._addrBasis).to.not.equal('0:0000000000000000000000000000000000000000000000000000000000000000')

  })

  it("set data", async () => {

    const promises = res.map(async (el, index) => {
      await callThroughMultisig({
        client,
        smcSafeMultisigWallet,
        abi: pkgStorage.abi,
        functionName: "fillContent",
        input: {
          chankNumber: index,
          part: base64ToHex(el),
        },
        dest: smcStorage.address,
        value: 1_000_000_000,
      });
    });

    await Promise.all(promises);

    complete = await smcStorage.run({
      functionName: "_complete",
    })
    console.log('Complete: ', complete.value._complete);
  });

  it("get part of data", async () => {
    const res = await smcStorage.run({
      functionName: "getInfo",
    });

    let str = "";
    for (var key in res.value.content) {
      str += res.value.content[key];
    }

    let mimeType = res.value.mimeType

    function hex_to_ascii(str1) {
      var hex = str1.toString();
      var str = '';
      for (var n = 0; n < hex.length; n += 2) {
        str += String.fromCharCode(parseInt(hex.substr(n, 2), 16));
      }
      return str;
    }

    mimeType = hex_to_ascii(mimeType);

    const pictBuff = hexToBase64(str);

    fs.writeFileSync(`./pictBuff.${mimeType}`, pictBuff, "base64");
  });
});