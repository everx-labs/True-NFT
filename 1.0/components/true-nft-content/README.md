# TrueNft Content
 
## System Description 
 
One of the main system concepts is blockchain as Key => Value storage. It consists of five smart contracts, three of which are implemented by NFT, and the other two are responsible for fast searches in the blockchain. NFT is deployed just once. And storage data does not affect the ownership transfer. Also content can be stored in any workchain due to the Storage contract. At the same time, you can easily find all NFT collections with the IndexBasis codeHash & Index contracts. And the code of these contracts should not be changed for all NFT implementations. This allows a global search across all NFT implementations. Therefore, the problem of storing data in ledgers or elsewhere has been solved.
 
## Smart contracts description
 
NftRoot - smart contract responsible for NFT release.
 
Data - contract storing information, which is also responsible for the owner change.
 
Storage - contract storing content, connected with Data contract. 
 
Index - contract used to find all NFTs for a specific owner.
 
IndexBasis - contract used to find all Roots & all NFTs.
 
### Class diagram
 
[Class diagram](../../out/components/true-nft-content/uml/image-storage-class/image-storage-class.png)
 
## Transfer
 
Proposed transfer mechanism ensures data consistency in the blockchain. It should not be changed.
 
### Transfer sequence diagram

[Transfer mint diagram](../../out/components/true-nft-content/uml/image-storage-mint/image-storage.png)
[Transfer sequence diagram](../../out/components/true-nft-content/uml/image-storage-transfer/image-storage.png)
 
## Logic and Data
 
NftRoot, Data & Storage is responsible for specific components of the system. NftRoot mints NFT contained Data & Storage. It is highly customisable. Data is a contract storing NFT info. It is responsible for the ownership transfer. Storage content might be of a different nature including video files.
 
## Search
 
The global search is carried out using the IndexBasis contract, which contains the NftRoot address. Since the NftRoot address is included in the initialData of IndexBasis, there can be one basis for one root. It also contains the Data codeHash, which includes root address. It guarantees that any NFT can be found for this particular collection. Index contract code allows you to find all your NFTs with one query.
