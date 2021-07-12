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
