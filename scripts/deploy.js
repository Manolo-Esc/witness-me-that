const hre = require("hardhat");

async function main() {
    // 1. Load the compiled "mould" of the contract (bytecode + ABI).
    const PaymentRegistry = await hre.ethers.getContractFactory("PaymentRegistry");

    // 2. Send the deployment transaction. Careful: at this point the
    //    transaction is only *sent*, it is not confirmed by the network yet.
    const paymentRegistry = await PaymentRegistry.deploy();

    // 3. Wait for the transaction to be mined. Without this, on a real network
    //    (Sepolia) the script could finish before the contract exists.
    //    In ethers v5 this function was called .deployed()
    await paymentRegistry.waitForDeployment();

    // In ethers v6 the address comes from getAddress() (before: .address)
    console.log("Contract deployed at:", await paymentRegistry.getAddress());
}

// Recommended pattern: do NOT use process.exit(), which kills the process
// abruptly and can truncate pending log writes. Just set the exit code.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
