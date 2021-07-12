TrueNFT is the implementation of on-chain NFT technology on the Free TON blockchain.

This technology was developed to:
- make sure the entirety of the NFT data is stored on the blockchain, without relying on any third-party protocols
- simplify and standardise queries for finding collections and user's NFT tokens
- enable users to interact with their tokens in decentralized browsers and dApps knowing only their own address, and to transfer them knowing just the recipient's address.

These requirements are met if the system is implemented based on the following contracts:
- NFTRoot - customizable contract containing minting logic and information about a collection
- NFTBasis - fixed contract for simple collection search
- NFTIndex - fixed contract, index for simple user token search
- NFTData - customizable contract containing token data and transfer logic. 

Explore core implementation and usage examples here -> https://github.com/tonlabs/True-NFT/tree/main/components/true-nft-core

**Changelog 12 Jul 2021**

The problem with the old specification - a query of all NftData on all NftRoots for a specific owner (Surf address) was needed
The solution - an additional search index

- search indexes were implemented within a single contract, so only one code needs to be stored
- transfer mechanism was moved from NftRoot to NftData, so owner change with a single internal message is guaranteed
- the amount of code didn't change, while all primary queries are implemented in indexes and basis
- contract name was changed from Nft to Index (IndexOwner & IndexOwnerRoot are shown as different classes in the scheme, even though it's a single contract - it's deployed with different salt, therefore the hashCodes are different)
- mapping in NftRoot and the mechanism of waiting for owner change was removed
