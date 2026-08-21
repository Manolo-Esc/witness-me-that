const hre = require("hardhat");

// Configuration comes from environment variables, so the script never needs
// editing. Example:
//   CONTRACT_ADDRESS=0x... FILE_HASH=abc... FILE_URL=ipfs://... \
//     npx hardhat run scripts/interact.js --network localhost
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS;
const FILE_HASH = process.env.FILE_HASH || "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
const FILE_URL = process.env.FILE_URL || "ipfs://QmExampleHashForThisTutorial";

async function main() {
    // Validate the configuration BEFORE talking to the network, so the error is
    // readable instead of a cryptic ethers failure halfway through the call.
    if (!CONTRACT_ADDRESS) {
        throw new Error(
            "CONTRACT_ADDRESS is not set. Deploy the contract first with\n" +
            "  npx hardhat run scripts/deploy.js --network localhost\n" +
            "then pass the address it prints:\n" +
            "  CONTRACT_ADDRESS=0x... npx hardhat run scripts/interact.js --network localhost"
        );
    }
    if (!hre.ethers.isAddress(CONTRACT_ADDRESS)) {
        throw new Error(`CONTRACT_ADDRESS is not a valid address: ${CONTRACT_ADDRESS}`);
    }

    // The signer is the account that signs and pays for gas. It comes from the
    // private key configured for the network (locally, a throwaway test account).
    const [signer] = await hre.ethers.getSigners();
    console.log("Using account:", signer.address);

    // getContractAt means "a contract already exists at this address, give me
    // the remote control to talk to it" — unlike deploy, which creates one.
    const paymentRegistry = await hre.ethers.getContractAt(
        "PaymentRegistry",
        CONTRACT_ADDRESS,
        signer
    );

    // --- Write: this DOES cost gas, because it changes the network state ---
    console.log("\nRegistering payment...");
    const tx = await paymentRegistry.registerPayment(FILE_HASH, FILE_URL);
    console.log("  Transaction sent:", tx.hash);

    // tx.wait() waits for the transaction to be mined and returns the receipt.
    const receipt = await tx.wait();
    console.log("  Confirmed in block", receipt.blockNumber, "- gas used:", receipt.gasUsed.toString());

    // --- Read: this is FREE, it creates no transaction ---
    // It is a read-only (view) call that the node answers immediately.
    const payments = await paymentRegistry.getPayments(signer.address);
    console.log(`\nPayments registered by ${signer.address}: ${payments.length}`);

    for (const [index, payment] of payments.entries()) {
        // uint256 values arrive as BigInt in ethers v6. The timestamp is in
        // seconds, but JavaScript works in milliseconds.
        const registeredAt = new Date(Number(payment.timestamp) * 1000).toISOString();
        console.log(`  [${index}] ${registeredAt}`);
        console.log(`       hash: ${payment.fileHash}`);
        console.log(`       url:  ${payment.fileURL}`);
        console.log(`       payer: ${payment.payer}`);
    }
}

main().catch((error) => {
    console.error(error.message ?? error);
    process.exitCode = 1;
});
