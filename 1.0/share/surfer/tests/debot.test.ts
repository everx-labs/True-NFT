import { createClient, NETWORK_MAP } from "@ton-contracts/utils/client";
import TonContract from "@ton-contracts/utils/ton-contract";
import { TonClient } from "@tonclient/core";
import pkgSafeMultisigWallet from "../../../ton-packages/SetCodeMultisig.package";

import pkgIndex from "../ton-packages/Index.package";
import pkgIndexBasis from "../ton-packages/IndexBasis.package";
import pkgData from "../ton-packages/Data.package";
import pkgNftRoot from "../ton-packages/NftRoot.package";
import pkgNftDebot from "../ton-packages/NftDebot.package";
import pkgManager from "../ton-packages/Manager.package";
import { base64ToHex } from "@ton-contracts/utils/convert";
const fs = require("fs");

describe("main test debot", () => {
  let client: TonClient;
  let smcSafeMultisigWallet: TonContract;
  let smcDebot: TonContract;
  let smcNftRoot: TonContract;
  let smcNft: TonContract;
  let smcNftData: TonContract;
  let smcManager: TonContract;

  before(async () => {
    client = createClient();
    smcSafeMultisigWallet = new TonContract({
      client,
      name: "SafeMultisigWallet",
      tonPackage: pkgSafeMultisigWallet,
      address: process.env.MULTISIG_ADDRESS,
      keys: {
        public: process.env.MULTISIG_PUBKEY as string,
        secret: process.env.MULTISIG_SECRET as string,
      },
    });
  });

  it("deploy Nft Debot", async () => {

    const managerKeys = await client.crypto.generate_random_sign_keys();
    smcManager = new TonContract({
      client,
      name: "NftManager",
      tonPackage: pkgManager,
      keys: managerKeys,
    });
    await smcManager.calcAddress();
    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcManager.address,
        value: 1_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });
    await smcManager.deploy({
      input: {
        rootCode: pkgNftRoot.image
      }
    });

    const newkeys = await client.crypto.generate_random_sign_keys();
    const keys = {
        public: process.env.DEBOT_PUBKEY as string || newkeys.public,
        secret: process.env.DEBOT_SECRET as string || newkeys.secret,
    };
    smcDebot = new TonContract({
      client,
      name: "NftDebot",
      tonPackage: pkgNftDebot,
      keys,
    });
    await smcDebot.calcAddress();
    console.log('Debot addr', smcDebot.address);
    console.log('Debot keys', JSON.stringify(keys));

    await smcSafeMultisigWallet.call({
      functionName: "sendTransaction",
      input: {
        dest: smcDebot.address,
        value: 1_000_000_000,
        bounce: false,
        flags: 2,
        payload: "",
      },
    });

    await smcDebot.deploy({});

    await new Promise<void>((resolve) => {
      fs.readFile(
        "./build/NftDebot.abi.json",
        "utf8",
        async function (err, data) {
          if (err) {
            return console.log({ err });
          }
          const buf = Buffer.from(data, "ascii");
          const hexvalue = buf.toString("hex");
          await smcDebot.call({
            functionName: "setABI",
            input: {
              dabi: hexvalue,
            },
          });
          resolve();
        }
      );
    });

    const codeRootNft = await client.boc.get_code_from_tvc({
      tvc: pkgNftRoot.image,
    });
    const codeNftBasis = await client.boc.get_code_from_tvc({
      tvc: pkgIndexBasis.image,
    });
    const codeData = await client.boc.get_code_from_tvc({
      tvc: pkgData.image,
    });
    const codeIndex = await client.boc.get_code_from_tvc({
      tvc: pkgIndex.image,
    });

    await smcDebot.call({
      functionName: "setNftRootCode",
      input: codeRootNft,
    });
    await smcDebot.call({
      functionName: "setBasisCode",
      input: codeNftBasis,
    });
    await smcDebot.call({
      functionName: "setDataCode",
      input: codeData,
    });
    await smcDebot.call({
      functionName: "setIndexCode",
      input: codeIndex,
    });
    await smcDebot.call({
      functionName: "setManager",
      input: {
        addr: smcManager.address,
      }
    });
    const bitmap = fs.readFileSync("./tests/surfer@3x.png");
    const strData = Buffer.from(bitmap).toString("base64");

    const length = 15000;
    const pattern = new RegExp(".{1," + length + "}", "g");
    let res = strData.match(pattern);

    const promises = res.map(async (el, index) => {
      await smcDebot.call({
        functionName: "setContent",
        input: {
          surfContent: base64ToHex(el),
        }
      });
      console.log(0, index);
    });

    await Promise.all(promises);
    
    console.log(
      `tonos-cli --url ${NETWORK_MAP[process.env.NETWORK]} debot fetch ${smcDebot.address}\n`
    );
  });
});