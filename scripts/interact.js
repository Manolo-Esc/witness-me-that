const { ethers } = require("hardhat");

async function main() {
    const contractAddress = "DIRECCION_DEL_CONTRATO";
    const PaymentRegistry = await ethers.getContractAt("PaymentRegistry", contractAddress);

    // Registrar un pago
    const tx = await PaymentRegistry.registerPayment("HASH_DEL_ARCHIVO", "IPFS_URL"); // esto es lo unico que consume ethers (es lo unico q cambia el estado de la red)
    await tx.wait();
    console.log("Pago registrado!");

    // Obtener pagos de un usuario
    const payments = await PaymentRegistry.getPayments("DIRECCION_DEL_USUARIO");
    console.log("Pagos:", payments);
}

main();

