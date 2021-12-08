# TrueNft Core

## Description of system

The system is built on the concept that blockchain is Key => Value storage. It consists of four smart contracts, two of which are implemented by NFT, and two are required for fast searches in the blockchain. It is important to note, the data that make up the NFT content is deployed once and does not affect the transfer of ownership. At the same time, you can easily find all NFT collections by the codeHash of the IndexBasis and Index contracts, while the code of these contracts is assumed to be unchanged for all NFT implementations. This approach will provide a global search across all NFT implementations. Based on this, it becomes obvious that the problem of storing data in ledgers or otherwise has been solved.

## Smart contracts description 

NftRoot - A smart contract that is responsible for the release of NFT.

Data - The contract stores information, which is essentially NFT, and is also responsible for changing the owner. 

Index - The contract that is used to find all NFTs for a specific owner. 

IndexBasis - The contract that is used to find all Roots and all NFTs.

### Class diagram

[Class diagram](../../out/components/true-nft-core/uml/NFT-v2/NFT-v2.png)

## Transfer

The proposed transfer mechanism ensures data consistency in the blockchain. It is not recommended to change it.

### Transfer sequence diagram

[Transfer mint diagram](../../out/components/true-nft-core/uml/NFT-v2-sequence-mint/NFT-v2.png)
[Transfer sequence diagram](../../out/components/true-nft-core/uml/NFT-v2-sequence-transfer/NFT-v2.png)

## Logic and Data

NftRoot and Data separate data storage and logic in the system. Data is a data warehouse that can contain content of a completely different nature, up to images. He is responsible for the transfer of ownership. NftRoot is responsible for minting NFT, but may contain other functionality such as writing. 

## Search

The global search is carried out using the IndexBasis contract, which contains the NftRoot address. Since the NftRoot address is included in the initialData of IndexBasis, there can be one basis for one root. It also contains the Data codeHash, which in turn is salted with the root address. Using this codeHash, you can find all the Data for this root. Using the Index contract code, you can find all your NFT with one query.
