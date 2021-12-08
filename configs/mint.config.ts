export default {
  collection:
    "0:80dce0d0c574805be65f6bafde6719e1b3f2c4359f664ee6628254b443534a4b", // collection address where to mint
  // array of NFTs
  items: [
    {
      wid: 0, // NFT content workchainId
      name: "test NFT", // name of NFT
      descriprion: "test NFT description", // description of NFT
      mimeType: "image/jpg", // mimeType of NFT content
      royalty: 100, // royalty part, range between 0 and 100000, where 100000 is 100.000%
      royaltyMin: 1, // minimum recieve in grams (author will recieve biggest part)
      meta: {
        height: 0, // optional
        width: 0, // optional
        duration: 0, // optional
        extra: "", // optional
        json: "", // optional
      },
      content: "./configs/1.jpg",
    },
  ],
} as const;
