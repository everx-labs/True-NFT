import { KeyPair, TonClient } from "@tonclient/core";
import pkgSafeMultisigWallet from "../ton-packages/SCMS.package";
import pkgNftRoot from "../ton-packages/NftRootCustomMint.package";
import pkgIndexBasis from "../ton-packages/IndexBasis.package";
import pkgData from "../ton-packages/Data.package";
import pkgIndex from "../ton-packages/Index.package";
import pkgDataChunk from "../ton-packages/DataChunk.package";
import { createClient, TonContract } from "@rsquad/ton-utils";
import { hexToUtf8, utf8ToHex } from "@rsquad/ton-utils/dist/convert";
import {
  callThroughMultisig,
  sendThroughMultisig,
} from "@rsquad/ton-utils/dist/net";
import { TonPackage } from "@rsquad/ton-utils/dist/ton-contract";
import config from "../configs/deploy-collection.config";

(async () => {
  try {
    if (
      !process.env.MULTISIG_ADDRESS ||
      !process.env.MULTISIG_PUBKEY ||
      !process.env.MULTISIG_SECRET
    ) {
      throw new Error(".env is not specified");
    }

    const client: TonClient = createClient();

    const smcWallet: TonContract = new TonContract({
      client,
      name: "SafeMultisigWallet",
      tonPackage: pkgSafeMultisigWallet,
      address: process.env.MULTISIG_ADDRESS,
      keys: {
        public: process.env.MULTISIG_PUBKEY,
        secret: process.env.MULTISIG_SECRET,
      },
    });

    let keys: KeyPair;

    keys = await client.crypto.generate_random_sign_keys();

    console.log("deploy and init collection");

    const smcNftRoot: TonContract = new TonContract({
      client,
      name: "NftRoot",
      tonPackage: pkgNftRoot,
      keys,
    });

    await smcNftRoot.calcAddress({
      initialData: {
        _addrOwner: smcWallet.address,
      },
    });

    await sendThroughMultisig({
      smcSafeMultisigWallet: smcWallet,
      dest: smcNftRoot.address,
      value: 1_000_000_000,
    });

    await smcNftRoot.deploy({
      input: {
        mintType: config.mintType,
        fee: config.fee,
        name: utf8ToHex(config.name),
        descriprion: utf8ToHex(config.description),
        icon: utf8ToHex(config.icon.type == "base64" ? config.icon.value : ""),
        addrAuthor: smcWallet.address,
      },
      initialData: {
        _addrOwner: smcWallet.address,
      },
    });

    const setCode = async (fnName: string, pkg: TonPackage) => {
      await callThroughMultisig({
        client,
        smcSafeMultisigWallet: smcWallet,
        abi: pkgNftRoot.abi,
        functionName: fnName,
        input: await client.boc.get_code_from_tvc({
          tvc: pkg.image,
        }),
        dest: smcNftRoot.address,
        value: 200_000_000,
      });
    };

    await setCode("setCodeIndex", pkgIndex);
    await setCode("setCodeIndexBasis", pkgIndexBasis);
    await setCode("setCodeData", pkgData);
    await setCode("setCodeDataChunk", pkgDataChunk);

    console.log(`collection address: ${smcNftRoot.address}`);

    const info = (await smcNftRoot.run({ functionName: "getInfo" })).value;
    console.log(`collection info: `, {
      ...info,
      name: hexToUtf8(info.name),
      descriprion: hexToUtf8(info.descriprion),
    });
    process.exit();
  } catch (err) {
    console.log("Error! ", err);
    process.exit();
  }
})();
