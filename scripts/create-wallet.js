const hre = require("hardhat");

async function main() {
    // Generates a brand-new random wallet locally. It does not touch any network.
    const wallet = hre.ethers.Wallet.createRandom();

    console.log("New throwaway wallet for tests");
    console.log("Address:     ", wallet.address);
    console.log("Private key: ", wallet.privateKey);
    console.log("");
    console.log("Add this to .env if you want to use it with Sepolia:");
    console.log(`PRIVATE_KEY="${wallet.privateKey}"`);
    console.log("");
    console.log("Send Sepolia ETH from a faucet to the address before deploying or interacting.");
    console.log("Never use this wallet for real funds.");
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
