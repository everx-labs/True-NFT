# TIP-31 tokens with surf (surf-truenft-rsquad) by TON Surf

The system consists of smart contracts that implement SurfMedal as a TIP-31 token.

## Smart contracts description 

NftRoot - A smart contract that is responsible for the release of NFT.

Data - The contract stores information, which is essentially NFT, and is also responsible for changing the owner.

Index - The contract that is used to find all NFTs for a specific owner.

IndexBasis - The contract that is used to find all Roots and all NFTs.

NftDebot - Debot for the administrator, which allows you to issue NFT and burn NFT. 

Manager - Auxiliary contract for deploying Root via Debot. 

## NftRoot
```sh
constructor (
    TvmCell codeIndex,
    TvmCell codeData,
    string name,
    string description,
    string tokenCode,
    uint256 totalSupply
);
```
##### Methods
- mintNft
Issues new NFT with comment from admin.
```sh
function mintNft (uint64 creationDate, string comment) public onlyOwner;
```
- deployBasis
Deploy a contract that adds this root to the global search.
```sh
function deployBasis (TvmCell codeIndexBasis) public onlyOwner;
```
- destructBasis
Destroys the contract, and thereby excludes this root from the global search.
```sh
function destructBasis () public onlyOwner;
```
- getInfo
Returns root parameters.
```sh
function getInfo() public view returns (
    string name,
    string description,
    string tokenCode,
    uint256 totalSupply,
    uint256 totalGrantedNfts,
    uint128 price
);
```
- setPrice
Sets the price for burning.
```sh
function setPrice (uint128 price) public onlyOwner;
```
- burn
Burnit NFT and sends funds to the owner of NFT.
```sh
function burn (address dataAddress, address owner) public onlyOwner;
```

## Data
```sh
constructor (
    address addrOwner,
    TvmCell codeIndex,
    address addrAuthor,
    string name,
    string description,
    string tokenCode,
    uint64 creationDate,
    string comment
);
```
##### Methods
- transferOwnership
Changes the owner of a specific NFT.
```sh
function transferOwnership (address addrTo) public onlyOwner;
```
- setNftDataContent
Used to download content that must be divided into parts not exceeding 15 kb.
```sh
function setNftDataContent (uint128 index, bytes part) public onlyOwner;
```
- getOwner
Returns owner address and NftData address.
```sh
function getOwner () public returns (address addrOwner, address addrNftData);
```
- getInfo
Returns NftData fields.
```sh
function getInfo () public returns(
    mapping(uint128 => bytes) content,
    address author,
    string name,
    string description,
    string tokenCode,
    uint64 creationDate,
    string comment
);
```
- destruct
Used for burning.
```sh
function destruct (address recipient) public onlyRoot;
```

## Index
```sh
constructor (address root) public onlyData;
```
##### Methods
- getInfo
Returns Nft fields.
```sh
function getInfo () public returns (
    address addrRoot,
    address addrOwner,
    address addrData
);
```
- destruct
Used for burning and transfer.
```sh
function destruct () public onlyData;
```

## IndexBasis
```sh
constructor () onlyRoot;
```
##### Methods
- getInfo
Returns Basis fields.
```sh
function getInfo () public returns (address addrRoot, uint256 codeHashData);
```
- destruct
Called to remove Root from global search.
```sh
function destruct () public onlyRoot;
```
