const hre = require("hardhat");

async function main() {
    // 1. Load the compiled contract 
    const PaymentRegistry = await hre.ethers.getContractFactory("PaymentRegistry");

    // 2. Send the deployment transaction. It is only sent, it is not confirmed by the network yet.
    const paymentRegistry = await PaymentRegistry.deploy();

    // 3. Wait for the transaction to be mined. 
    await paymentRegistry.waitForDeployment();

    console.log("Contract deployed at:", await paymentRegistry.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
