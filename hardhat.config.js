require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Load environment variables from .env file

const { ALCHEMY_API_URL, PRIVATE_KEY } = process.env;
const hasValidPrivateKey = /^0x[0-9a-fA-F]{64}$/.test(PRIVATE_KEY || "");

// Work out which network the command was invoked against (--network <name>).
const networkFlagIndex = process.argv.indexOf("--network");
const targetNetwork = networkFlagIndex !== -1 ? process.argv[networkFlagIndex + 1] : "hardhat";
const sepoliaAccounts = hasValidPrivateKey ? [PRIVATE_KEY] : [];

// Sepolia needs credentials that live in .env. If they are missing we print a message
if (targetNetwork === "sepolia") {
  const missing = [
    !ALCHEMY_API_URL && "ALCHEMY_API_URL",
    !PRIVATE_KEY && "PRIVATE_KEY",
    PRIVATE_KEY && !hasValidPrivateKey && "a valid PRIVATE_KEY"
  ].filter(Boolean);

  if (missing.length > 0) {
    console.error(`
Cannot use the Sepolia network: ${missing.join(" and ")} missing from your .env file
You can try everything locally, with no keys and no cost:
       npm run node:start
       npm run deploy:local
`);
    process.exit(1);
  }
}

module.exports = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: ALCHEMY_API_URL || "",
      accounts: sepoliaAccounts,
      chainId: 11155111
    }
  }
};
