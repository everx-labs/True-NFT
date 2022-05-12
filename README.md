# True-NFT 2.0

TNFT 2.0, released 03/01/2022

TrueNFT is the implementation of on-chain NFT technology on the Everscale blockchain.

This technology was developed to:

- make sure the entirety of the NFT data is stored on the blockchain, without relying on any third-party protocols
- simplify and standardise queries for finding collections and user's NFT tokens
- enable users to interact with their tokens in decentralized browsers and dApps knowing only their own address, and to transfer them knowing just the recipient's address.

SMART CONTRACTS DESCRIPTION

**Checks**

Creates checks for the necessary data when a contract is deployed.

**NftRoot**

Stores collection, not used by itself.

**NftRootBase**
Inherits NftRoot and does not customize logic.

**NftRootCustomMint**
Used by NFT collection distributor. Allows you to set the logic for minting.

**Data**
Most essential contract in TNFT 2.0. It contains data about the token’s owner and places this information directly on the blockchain. 

The Data contract is a part of the collection and is deployed only through NftRoot. After contract is deployed, search indexes are created. Also, this contract allows to customise sale and transfer logic and implement it to NFTs.

**DataChunk**
Contains a piece of content. Can only be deployed through the corresponding Data contract.

**Index**
Allows to search contracts for a specific user. When TNFT owner changes, Index updates: old Index is deleted and new one is deployed.

**IndexBasis**
Allows to search for all collections. The principle of operation is the same as that of the Index smart contract.

WHAT’S NEW

• Consistency is ensured for all collections. Now you can view data about the collection itself and the data about a specific NFT from any other collection.

• Standardized fields were added.

•  You can store large files using a new DataChunk contract and break one large file into pieces.

KNOWN ISSUES

• Manual compilation of Index and IndexBasis leads to problems displaying collections. To avoid this, please take these files from repository and use them as is without making any changes to them.

• Do not use IPFS to upload content for Collections as well as do not store links in the meta fields (for example, extra or json). This content won’t be displayed in TNFT 2.0. Surf displays content for Collections only if was uploaded using DataChunk.

• Using contracts of the previous version to display NFTs is no longer supported. Use TNFT 2.0 to display collections in Surf.

• If the TNFT content isn’t displayed correctly, please verify that mimeType and meta fields in the getInfo method meet the standards of MIME type: [https://en.wikipedia.org/wiki/Media_type](https://en.wikipedia.org/wiki/Media_type) 

• If the video or image measurements (height and width) aren’t specified in meta correctly or aren’t specified at all, these TNFT isn’t displayed in Collection.