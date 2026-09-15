# Witness me that!

[![Ethereum](https://img.shields.io/badge/Ethereum-3C3C3D?logo=ethereum&logoColor=white)](https://ethereum.org/) [![Solidity](https://img.shields.io/badge/Solidity-0.8.28-363636?logo=solidity&logoColor=white)](https://soliditylang.org/) [![Hardhat](https://img.shields.io/badge/Hardhat-2.22.19-F7DF1E)](https://hardhat.org/) [![Node.js](https://img.shields.io/badge/Node.js-%3E%3D18-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org/) [![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A hands-on tutorial, aimed at people with no blockchain background, on **how to store proofs on a blockchain**. Example use cases could include keeping records of NGO donations and payments, documents submitted by participants in a public tender, NFT metadata, game trophies, and similar proof-of-existence records.

The key idea is that persistent on-chain storage is expensive. The more data you store, the more gas you usually pay, although the exact cost also depends on how the data is written and on current network fees. So the solution is not to store the original document, but rather its **hash, optional metadata, and a link** to the file. Alternatively, [IPFS](https://ipfs.tech/) could be used to store the files, and the contract would store the CID instead of the hash and URL. The difference is where the responsibility for long-term file availability sits: a regular URL may be controlled by one owner, while anyone can pin a CID so it does not disappear.

To write to the blockchain, we use a **smart contract**. A smart contract is a program, together with its data, that lives inside the blockchain. It is published once, and from that moment on:
  - For a simple contract like this one, its code is immutable: it cannot be patched or upgraded after deployment. Some production systems use proxy patterns to make upgrades possible, but this tutorial does not.
  - Anyone can call its public functions without asking permission or going through your server. The code is visible and the interface can be inferred.
  - Writing costs money (gas) and requires signing a transaction. Reading from a script or frontend is free and creates no on-chain transaction, although reads performed inside another transaction still consume gas.
  - It runs the same way for everyone: each network node executes the same code and reaches the same result, which is why nobody has to trust you, and you do not have to trust anyone else.

The word *contract* comes from the fact that it behaves like an automatic agreement: the rules are written in code and are enforced by the network. There is no intermediary applying them, but the guarantees are only as good as the deployed code and any external systems it relies on. A smart contract can hold funds, issue tokens, or coordinate several parties; ours does the simplest useful thing, which is keeping a registry. It receives a document hash and a link to the document, then stores a timestamped record using the block time. In this tutorial that contract is `PaymentRegistry`.

The last aspect to consider is which **blockchain** to use. In this tutorial we use Ethereum smart contracts. That leaves several options for a production deployment. We could use Ethereum itself for maximum security, although it is the most expensive option. Another option is to use a *Layer 2* blockchain, such as Arbitrum, OP Mainnet, Base, or zkSync. L2 blockchains:
  - They execute transactions outside Ethereum Mainnet, reducing the amount of computation that needs to be performed directly on L1.
  - They batch and compress transactions, allowing many L2 transactions to share the cost of publishing data to Ethereum.
  - They use Ethereum as a settlement layer, with the exact security guarantees depending on their architecture and implementation.
  - They publish information to Ethereum that allows the L2 state to be verified or reconstructed.
  - Their transaction fees are generally much lower than Ethereum Mainnet fees.


## Requirements

- [Node.js](https://nodejs.org/) 18 or newer (tested on 24).


## The code

The actual contract code is only a few lines long. We use Hardhat to compile the contract, host the **simulated blockchain** used for local testing, and run the scripts that interact with the contract both locally and on a real public blockchain, even if in this tutorial that public chain is only a free testnet.

#### The contract
The example contract, [PaymentRegistry.sol](contracts/PaymentRegistry.sol), stores payment receipt proofs, not the receipt files themselves. For each record it keeps:

| Field | What it is for |
|---|---|
| `fileHash` | the file's fingerprint (e.g. SHA-256). Identifies the content without publishing it |
| `fileURL` | where the actual file lives |
| `timestamp` | the block timestamp when it was recorded; good as an approximate time, not as an exact clock |
| `payer` | who recorded it, set by the network itself |

The main function is `registerPayment`, which inserts a new record into the blockchain.


#### Deploy the contract
The deployment script is a tiny [Hardhat script](./scripts/deploy.js). It is intended to be run once per network. After that, you can interact with the deployed contract: register payments and retrieve previous records.

#### Interact with the contract
The code in [interact.js](./scripts/interact.js) shows examples of connecting to the contract and calling its functions.


## Local execution

Start by installing the dependencies:
```bash
npm install
```

Next, start the simulated blockchain node. Blockchain interactions always go through a specific node; in this case, the node is provided by Hardhat and only exists on your computer:
```bash
npm run node:start        # start the simulated blockchain (in the background)
```

Now deploy the contract to the simulated blockchain:
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


## Sepolia testnet execution

Sepolia is a *real* test blockchain: public, distributed, and run by its own validators, but where ETH is testnet ETH, intended to have no monetary value. We need a Sepolia node, real credentials, and testnet ETH.

### Node
As mentioned above, blockchain interactions always happen through a specific node. To avoid installing our own Sepolia node, we will use one provided by [Alchemy](https://www.alchemy.com/). Alchemy has free plans that are enough for this tutorial. If you create a new account, choose `infrastructure` as your interest and `Ethereum` as the blockchain if asked.

### Credentials
There are two ways to get the credentials needed to interact with the blockchain and receive testnet ETH.

- You can use a real wallet that supports Sepolia. The advantage is that it gives you a UI where you can see ETH movements.

- You can use the project's [create-wallet](./scripts/create-wallet.js) script. This gives you the wallet address and private key needed by the scripts.
```bash
npm run wallet:create
```

### Fund the account with testnet ETH
A faucet is a service that gives you a small amount of testnet cryptocurrency for free. You must provide the address derived from your private key, which is the only value you should ever share. Never share the private key.
Some faucets require you to hold a small amount of ETH on mainnet to prevent abuse, so they are not fully free unless you already have an Ethereum wallet that you are using for this tutorial.
An alternative, if you have a Gmail address, is the [Google faucet](https://cloud.google.com/application/web3/faucet/ethereum/sepolia).


### Run the full flow

Start by creating your `.env` file:
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

Interact with the contract:
```bash
CONTRACT_ADDRESS=0x... npm run interact:sepolia
```

### Check the result
You can inspect the transactions in any block explorer, for example https://sepolia.etherscan.io/.
If you search for the address derived from your private key, you should see the account funding transaction, the contract deployment, and the write transaction against the contract.
If you search for the contract address, you will see the test transaction and its data.


## Available commands

| Script | What it does |
|---|---|
| `npm run compile` | compiles the contracts in `contracts/`; this is also done automatically before deployment |
| `npm run clean` | deletes `artifacts/` and `cache/` |
| `npm run node` | simulated blockchain in the foreground (occupies the terminal, Ctrl+C to stop) |
| `npm run node:start` | simulated blockchain in the background, log in `hardhat_node.log` |
| `npm run node:stop` | stops the simulated blockchain |
| `npm run wallet:create` | creates a new wallet |
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


