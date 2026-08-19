# configurar el entorno y a escribir el smart contract en Solidity para registrar los pagos en Ethereum.  

---

## **1️⃣ Configuración del Entorno en Ubuntu**  

Antes de escribir el contrato, instala las herramientas necesarias:

### **Paso 1: Instalar Node.js y npm**  
Ethereum y Solidity se manejan principalmente con **Node.js** y **npm**. Para instalarlos:  

```bash
sudo apt update
sudo apt install nodejs npm -y
```

Verifica la instalación con:  
```bash
node -v
npm -v
```

---

### **Paso 2: Instalar Hardhat (Framework para Smart Contracts)**  
Hardhat es una de las mejores herramientas para desarrollar y desplegar contratos inteligentes.  

1. Crea un directorio para el proyecto:  
   ```bash
   mkdir eth-payments && cd eth-payments
   ```
2. Inicializa un proyecto con npm:  
   ```bash
   npm init -y
   ```
3. Instala Hardhat:  
   ```bash
   npm install --save-dev hardhat
   ```
4. Configura Hardhat:  
   ```bash
   npx hardhat
   ```
   Elige la opción **"Create an empty hardhat.config.js"**.

---

### **Paso 3: Instalar dependencias adicionales**  
```bash
npm install --save-dev @nomicfoundation/hardhat-toolbox dotenv ethers
```

- **`hardhat-toolbox`**: Conjunto de herramientas para desarrollar smart contracts.
- **`dotenv`**: Manejo de variables de entorno (útil para claves privadas).
- **`ethers.js`**: Librería para interactuar con Ethereum.

---

## **2️⃣ Código del Smart Contract**  
Ahora escribamos el contrato Solidity.  

Crea un directorio `contracts/` y dentro, un archivo `PaymentRegistry.sol`:  

```bash
mkdir contracts
nano contracts/PaymentRegistry.sol
```

### **Código del Smart Contract**  
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PaymentRegistry {
    struct Payment {
        string fileHash;  // Hash del archivo de pago (SHA-256, por ejemplo)
        string fileURL;   // Enlace al archivo (IPFS, Arweave, etc.)
        uint256 timestamp;
        address payer;
    }

    mapping(address => Payment[]) public payments;

    event PaymentRegistered(address indexed payer, string fileHash, string fileURL, uint256 timestamp);

    function registerPayment(string memory _fileHash, string memory _fileURL) public {
        require(bytes(_fileHash).length > 0, "El hash del archivo no puede estar vacío");
        require(bytes(_fileURL).length > 0, "El URL del archivo no puede estar vacío");

        payments[msg.sender].push(Payment(_fileHash, _fileURL, block.timestamp, msg.sender));

        emit PaymentRegistered(msg.sender, _fileHash, _fileURL, block.timestamp);
    }

    function getPayments(address _payer) public view returns (Payment[] memory) {
        return payments[_payer];
    }
}
```

### **¿Cómo funciona?**
1. **`registerPayment(string _fileHash, string _fileURL)`**  
   - Registra un pago con un **hash** y un **enlace** al archivo.
   - Emite un evento `PaymentRegistered` para dejar constancia en la blockchain.

2. **`getPayments(address _payer)`**  
   - Devuelve todos los pagos de un usuario específico.

---

## **3️⃣ Compilar y Desplegar el Smart Contract**  

### **Paso 1: Compilar el contrato**  
```bash
npx hardhat compile
```
Si todo está bien, verás un mensaje de éxito.

---

### **Paso 2: Configurar Red de Pruebas (Goerli, Sepolia, Polygon, etc.)**  
1. Crea un archivo `.env` en el directorio del proyecto:  
   ```bash
   nano .env
   ```
2. Añade tus credenciales:  
   ```ini
   ALCHEMY_API_URL="https://eth-sepolia.g.alchemy.com/v2/TU_CLAVE_ALCHEMY"
   PRIVATE_KEY="TU_CLAVE_PRIVADA"
   ```

   - **ALCHEMY_API_URL**: Obtén una API Key gratis en [Alchemy](https://www.alchemy.com/).
   - **PRIVATE_KEY**: Usa una wallet como Metamask y exporta tu clave privada.

---

### **Paso 3: Modificar `hardhat.config.js`**  
Edita `hardhat.config.js` para agregar la configuración de la red:  

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    sepolia: {
      url: process.env.ALCHEMY_API_URL,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
```

---

### **Paso 4: Crear Script de Despliegue**  
1. Crea una carpeta `scripts/`:  
   ```bash
   mkdir scripts
   ```
2. Crea un archivo `deploy.js`:  
   ```bash
   nano scripts/deploy.js
   ```
3. Añade el código de despliegue:  
   ```javascript
   const hre = require("hardhat");

   async function main() {
       const PaymentRegistry = await hre.ethers.getContractFactory("PaymentRegistry");
       const paymentRegistry = await PaymentRegistry.deploy();
       await paymentRegistry.deployed();

       console.log("Contrato desplegado en:", paymentRegistry.address);
   }

   main().catch((error) => {
       console.error(error);
       process.exitCode = 1;
   });
   ```

---

### **Paso 5: Desplegar el contrato en la red de pruebas**  
Ejecuta el script:  
```bash
npx hardhat run scripts/deploy.js --network sepolia
```
Si todo sale bien, obtendrás la dirección del contrato en la blockchain.

---

## **4️⃣ Interactuar con el Smart Contract**  

Para interactuar con el contrato, puedes usar `ethers.js` en un script Node.js o en una DApp con React.  

Ejemplo de interacción desde un script:  

1. Crea un archivo `interact.js`:  
   ```bash
   nano scripts/interact.js
   ```
2. Añade el siguiente código:  
   ```javascript
   const { ethers } = require("hardhat");

   async function main() {
       const contractAddress = "DIRECCION_DEL_CONTRATO";
       const PaymentRegistry = await ethers.getContractAt("PaymentRegistry", contractAddress);

       // Registrar un pago
       const tx = await PaymentRegistry.registerPayment("HASH_DEL_ARCHIVO", "IPFS_URL");
       await tx.wait();
       console.log("Pago registrado!");

       // Obtener pagos de un usuario
       const payments = await PaymentRegistry.getPayments("DIRECCION_DEL_USUARIO");
       console.log("Pagos:", payments);
   }

   main();
   ```

3. Ejecuta el script:  
   ```bash
   npx hardhat run scripts/interact.js --network sepolia
   ```

---

## **🚀 Próximos Pasos**
✅ **Configurar IPFS** para almacenar archivos.  
✅ **Crear una interfaz web (React + ethers.js)** para facilitar el uso.  
✅ **Optimizar costos con Polygon o L2 como Optimism.**

---

Este código te da una base sólida para gestionar pagos en Ethereum con almacenamiento descentralizado. ¿Quieres que agreguemos algo más, como cifrado de archivos o integración con una DApp? 😃