# witness-me-that



Licencia y disclaimer
Badges
  - ethereum/solidity
  - hardhat
  - node


A hands-on tutorial, aimed at people with no blockchain background, on **how to store proofs on a blockchain**. Ejemplos de casos de uso podrían ser guardar registros de donaciones y pagos de una ONG, de documentación remitida por los participantes en un concurso público, información sobre NFTs y trofeos en juegos... 

La idea feliz es que en blockchains el coste económico es directamente proporcional al tamaño de la información almacenada. El precio de cada byte guardado es alto. Así que la solución no es guardar el documento original sino su **hash, metadata opcional y un link** al fichero. Alternativamente se podría usar [IPFS](https://ipfs.tech/) para almacenar los ficheros y en vez de guardar en el blockchain el hash y el URL se guardaría el CID. La diferencia está en dónde se pone la responsabilidad de que el archivo en sí esté disponible dentro de un tiempo: posiblemente alguien es propietario exclusivo del fichero en un URL pero cualquiera podría pinear un CID para que no borre.

Para escribir en la blockchain se usa un **smart contract**. Un smart contract es un programa y sus datos que viven dentro de la blockchain. Se publica una vez y desde ese momento:
  - Su código es inmutable: no se puede parchear ni actualizar. Lo que despliegas es lo que habrá para siempre.
  - Cualquiera puede llamar a sus funciones públicas, sin pedir permiso ni pasar por tu servidor. El código es visible y la interfaz, deducible.
  - Escribir cuesta dinero (gas) y requiere firmar una transacción; leer es gratis y no deja rastro.
  - Se ejecuta igual para todos: cada nodo de la red corre el mismo código y llega al mismo resultado, y eso es lo que hace que nadie tenga que confiar en ti — ni tú en nadie.

Lo de "contrato" viene de que hace de acuerdo automático: las reglas están escritas en el código y se cumplen solas, sin intermediario que las aplique ni posibilidad de saltárselas. Un smart contract puede custodiar fondos, emitir tokens o coordinar a varias partes; el nuestro hace lo más simple posible, que es llevar un registro: recibe el hash de un documento, un enlace a él, y deja constancia sellada con la fecha del bloque. En este tutorial ese contrato es PaymentRegistry.

El último aspecto a considerar es la **blockchain** a utilizar. Para este tutorial usaremos smart contracts de Ethereum. Así tendremos varias alternativas para desplegar la solución en producción. Podremos usar la propia Ethereum para máxima seguridad aunque es la solución más cara. Otra alternativa es usar un blockchain *Layer 2*, por ejemplo Arbitrum, OP Mainnet, Base, or zkSync. Los blockchain L2:   
  - They execute transactions outside Ethereum Mainnet, reducing the amount of computation that needs to be performed directly on L1.
  - They batch and compress transactions, allowing many L2 transactions to share the cost of publishing data to Ethereum.
  - They use Ethereum as a settlement layer, with the exact security guarantees depending on their architecture and implementation. 
  - They publish information to Ethereum that allows the L2 state to be verified or reconstructed.
  - Their transaction fees are generally much lower than Ethereum Mainnet fees.


## Requirements

- [Node.js](https://nodejs.org/) 18 or newer (tested on 24).


## The code

El código en sí es de apenas una docena de líneas. Usamos la librería Hardhat para compilar el contrato, para albergar la **simulated blockchain** que utilizamos en las pruebas en local y para ejecutar los programas que interactuan con el contrato tanto en local como en la blockchain real (aunque de test y gratuita).

### The contract
The example contract, [PaymentRegistry.sol](contracts/PaymentRegistry.sol), stores payment receipts. For each record it keeps:

| Field | What it is for |
|---|---|
| `fileHash` | the file's fingerprint (e.g. SHA-256). Identifies the content without publishing it |
| `fileURL` | where the actual file lives  |
| `timestamp` | when it was recorded, set by the network itself |
| `payer` | who recorded it, set by the network itself |

La función principal es `registerPayment` que inserta un nuevo registro en la blockchain


### Deploy the contract
It is a [three lines code](./scripts/deploy.js) using hardhat. It is intended to be run just once. Después ya se puede interactuar con el contrato: registrar pagos y obtener pagos pasados

### Interactuar con el contrato
The code in the script [interact.js](./scripts/interact.js) muestra ejemplos de conectar con el contrato y llamar a sus funciones. 


## Ejecución en local 

Empezamos intalando las dependencias
```bash
npm install
```

A continuación iniciamos el nodo de la blockchain simulada. Las interacciones con la blockchain se hacen siempre contra un nodo específico, en este caso contra el que nos proporciona hardhat y que no tiene validez fuera de nuestro ordenador:
```bash
npm run node:start        # start the simulated blockchain (in the background)
```

Ahora desplegamos nuestro contrato en la blockchain simulada
```bash
npm run deploy:local      # deploy the contract -> prints its address
```

Copy the address it prints and use it to interact:
```bash
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3 npm run interact:local
```
And when you are done:
```bash
npm run node:stop         # stop the simulated blockchain
```


## Ejecución en the Sepolia testnet

Sepolia is a *real* test blockchain: public, distributed, with its own validators, but where ETH is worthless. Necesitaremos un nodo de Sepolia, credenciales reales y testnet ethers

### Nodo
Como decíamos, las interacciones con la blockchain se hacen siempre contra un nodo específico. Para no tener que instalar nuestro propio nodo de Sepolia usaremos un nodo proporcionado por [Alchemy](https://www.alchemy.com/). Alchemy tiene planes gratuitos suficientes para nuestro propósito. Si haces una nueva cuenta, selecciona `infraestructura` como interés y `Ethereum` como blockchain si te pregunta por ellas. 

### Credenciales
Hay dos formas en las que puedes obtener las credenciales necesarias para interactuar con la blockchain y para obtener testnet ethers. 

- Puedes usar un Wallet real que soporte Sepolia. La ventaja es que te proporciona un UI en el que ver los movimientos de ethers

- Usar el script [create-wallet](./scripts/create-wallet.js) del proyecto. Suficiente para que los programas funcionen
```bash
npm run wallet:create 
```

### Cargar la cuenta con testnet ethers
Un faucet es un servicio que te entrega gratuitamente una pequeña cantidad de criptomoneda de testnet. Tienes que pasar la dirección derivada de la clave, que es el único dato que tendrás que compartir siempre. Nunca la clave privada.
La mayoría de los faucets te pedirán que tengas 0.001 eth en la red principal para evitar abusos por lo que no se pueden usar de forma gratuita salvo que ya tuvieras un wallet ethereum que estés usando en este tutorial. 
Una alternativa si tienes una dirección de correo de gmail es usar el [faucet de google](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)


### Ejecución del flujo completo

Empieza creando tu fichero .env
```bash
cp .env.example .env
```

Then fill it:
- `ALCHEMY_API_URL` — the HTTPS URL of an Alchemy app pointing at Sepolia. You can find it in the `endpoints` section.
- `PRIVATE_KEY` 

Deploy the contract and write down its address
```bash
npm run deploy:sepolia
```

Interactúa con el contrato
```bash
CONTRACT_ADDRESS=0x... npm run interact:sepolia
```

### Comprobación:
Puedes ver las transacciones realizadas en cualquier explorador de bloques, por ejemplo https://sepolia.etherscan.io/
Si buscas por la dirección de tu clave deberías ver las transacciones de carga de saldo, deploy del contrato y escritura en el contrato.
Si buscas por la dirección del contrato verás la transacción de prueba y sus datos 


## Available commands

| Script | What it does |
|---|---|
| `npm run compile` | compiles the contracts in `contracts/` It is done automatically |
| `npm run clean` | deletes `artifacts/` and `cache/` |
| `npm run node` | simulated blockchain in the foreground (occupies the terminal, Ctrl+C to stop) |
| `npm run node:start` | simulated blockchain in the background, log in `hardhat_node.log` |
| `npm run node:stop` | stops the simulated blockchain |
| `npm run wallet:create` | creates a new wallet,
| `npm run deploy:local` | deploys against the node from `node:start` |
| `npm run interact:local` | registers and reads a payment on that node |
| `npm run deploy:sepolia` | deploys to the Sepolia testnet (requires `.env`) |
| `npm run interact:sepolia` | interacts with the contract on Sepolia (requires `.env`) |

Environment variables understood by `interact`:

| Variable | Required | Default |
|---|---|---|
| `CONTRACT_ADDRESS` | yes | — |
| `FILE_HASH` | no | an example SHA-256 hash |
| `FILE_URL` | no | an example IPFS URL |






