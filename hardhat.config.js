require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const { ALCHEMY_API_URL, PRIVATE_KEY } = process.env;

// Work out which network the command was invoked against (--network <name>).
const networkFlagIndex = process.argv.indexOf("--network");
const targetNetwork = networkFlagIndex !== -1 ? process.argv[networkFlagIndex + 1] : "hardhat";

// Sepolia needs credentials that live in .env (which is never committed).
// If they are missing we print a clear message, but only when Sepolia is
// actually the target: that way the project still compiles and runs locally
// without any keys at all.
if (targetNetwork === "sepolia") {
  const missing = [
    !ALCHEMY_API_URL && "ALCHEMY_API_URL",
    !PRIVATE_KEY && "PRIVATE_KEY"
  ].filter(Boolean);

  if (missing.length > 0) {
    console.error(`
Cannot use the Sepolia network: ${missing.join(" and ")} missing from your .env file

  1. Copy the template:   cp .env.example .env
  2. Edit .env and fill in:
       ALCHEMY_API_URL  the HTTPS URL of your Alchemy app pointing at Sepolia
       PRIVATE_KEY      the private key of a THROWAWAY test account
                        (never an account holding real funds)
  3. Get some free test ETH from a faucet (see the README for a list)

In the meantime you can try everything locally, with no keys and no cost:
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
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      chainId: 11155111
    }
  }
};
