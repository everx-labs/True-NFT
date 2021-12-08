export default {
  mintType: 0, // 0 — OnlyOwner, 1 — OnlyFee, 2 — OnwerAndFee, 3 — All
  fee: 0, // fee amount in grams
  name: "test", // name of NFT collection
  description: "test_desc", // description of NFT collection
  icon: {
    type: "base64",
    value: "", // !IMPORTANT don't use icon more then 8kb
  },
} as const;
