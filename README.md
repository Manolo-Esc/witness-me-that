


- gitignore


- Compilar el contrato
  - en el folder del proyecto: npx hardhat compile

- Desplegar el contrato en la red de pruebas
  - npx hardhat run scripts/deploy.js --network sepolia

- Interactuar:
  - npx hardhat run scripts/interact.js --network sepolia

https://hardhat.org/tutorial
https://docs.alchemy.com/docs/how-to-deploy-a-smart-contract-to-the-sepolia-testnet

- Conceptos
  - Sepolia: testnet
  - Alchemy (¿y Infura, QuickNode?): el "AWS" del blockchain. Evita tener que gestionar un nodo
  - L2 (layer 2): Optimism, Arbitrum, zkSync, Polygon zkEVM y Polygon Miden: 
    - Funcionan encima de Ethereum. dependen completamente de Ethereum para su seguridad
    - Agrupan y Procesan transacciones fuera de la mainnet y luego envían la información de vuelta a Ethereum.
    - Los datos del contrato y las transacciones existen en la L2, Solo una prueba de validez o resumen del estado se almacena en Ethereum L1.
    - Usan ETH como gas, porque las transacciones eventualmente se liquidan en Ethereum.
    - son más baratas por un truco clave: agrupar muchas transacciones en una sola antes de enviarlas a Ethereum.
      - Optimistic Rollups (Optimism, Arbitrum): Asumen que las transacciones son válidas a menos que alguien pruebe lo contrario. Tienen un tiempo de espera (~7 días) para disputas.
      - ZK-Rollups (zkSync, Polygon zkEVM): Usan pruebas criptográficas que garantizan que las transacciones son válidas sin necesidad de esperas.
  - Sidechain: Polygon PoS
    - Es una blockchain separada, con su propio mecanismo de consenso y seguridad (sus propios validadores), aunque conectada a Ethereum.
    - Usa MATIC para gas.
    - Mayor independencia, transacciones aún más rápidas y baratas.
    - en una sidechain, los datos de las transacciones se quedan en la sidechain y no se publican en Ethereum.
    - la conexión solo maneja conversiones de tokens mediante un bridge, pero no las transacciones.
  - Si lanzas una dApp, tienes que elegir en qué red desplegarla:
    - Máxima seguridad: Usa Ethereum mainnet (costoso, pero ultra seguro).
    - Escalabilidad con seguridad de Ethereum: Optimism, Arbitrum, zkSync o Polygon zkEVM.
    - Más velocidad y costos ultra bajos: Usa Polygon PoS, pero aceptando que no hereda seguridad de Ethereum.

