# TrueNft Core

## Description of system

The system is built on the concept that blockchain is Key => Value storage. It consists of four smart contracts, two of which are implemented by NTF, and two are required for fast searches in the blockchain. It is important to note, the data that make up the NTF content is deployed once and does not affect the transfer of ownership. At the same time, you can easily find all NTF collections by the codeHash of the NftBasis and Nft contracts, while the code of these contracts is assumed to be unchanged for all NTF implementations. This approach will provide a global search across all NTF implementations. Based on this, it becomes obvious that the problem of storing data in ledgers or otherwise has been solved.

## Smart contracts description 

NftRoot - A smart contract that is responsible for the release of NTF, as well as for the change of ownership.

NftData - The contract stores information, which is essentially NFT. 

Nft - The contract that is used to find all NFTs within Root for a specific owner. 

NftBasis - The contract that is used to find all Roots and all NFTs.

### Class diagram

[Class diagram](../../out/components/core/uml/TrueNft/TrueNft.png)

## Transfer

The proposed transfer mechanism ensures data consistency in the blockchain. It is not recommended to change it.

### Transfer sequence diagram

[Transfer sequence diagram](../../out/components/core/uml/Transfer/TrueNft.png)

## Logic and Data

NftRoot and NftData separate data storage and logic within the system. NftData is a data warehouse that can contain content of a completely different nature, up to images. NftRoot is responsible for minting NTF and transfer ownership, but may contain other features, such as burning. 

## Search

The global search is carried out using the NftBasis contract, which contains the NftRoot address. Since the NftRoot address is included in the initialData of NftBasis, there can be one basis for one root. It also contains the NftData codeHash, which in turn is salted with the root address. Using this codeHash, you can find all the NftData for this root. 
