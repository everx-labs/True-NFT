import { createClient } from "@ton-contracts/utils/client";
import TonContract from "@ton-contracts/utils/ton-contract";
import { TonClient } from "@tonclient/core";
import pkgSafeMultisigWallet from "../../../ton-packages/SetCodeMultisig.package";
import pkgMSIG from "../ton-packages/MSIG.package";

import pkgNft from "../ton-packages/Nft.package";
import pkgNftBasis from "../ton-packages/NftBasis.package";
import pkgNftData from "../ton-packages/NftData.package";
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
    
    const keys = await client.crypto.generate_random_sign_keys();
    smcDebot = new TonContract({
      client,
      name: "NftDebot",
      tonPackage: pkgNftDebot,
      keys,
    });
    await smcDebot.calcAddress();
    console.log('Debot addr', smcDebot.address);

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
      tvc: pkgNftBasis.image,
    });
    const codeNftData = await client.boc.get_code_from_tvc({
      tvc: pkgNftData.image,
    });
    const codeNft = await client.boc.get_code_from_tvc({
      tvc: pkgNft.image,
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
      functionName: "setNftDataCode",
      input: codeNftData,
    });
    await smcDebot.call({
      functionName: "setNftCode",
      input: codeNft,
    });
    await smcDebot.call({
      functionName: "setManager",
      input: {
        addr: smcManager.address,
      }
    });
    const bitmap = fs.readFileSync("./tests/surfer.jpg");
    const strData = new Buffer(bitmap).toString("base64");

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
      `./bin/tonos-cli --url http://0.0.0.0 debot fetch ${smcDebot.address}\n`
    );
  });
});