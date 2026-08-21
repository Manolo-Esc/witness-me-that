# witness-me-that

A hands-on tutorial, aimed at people with no blockchain background, on **how to
store proofs on a blockchain**: recording the hash of a file together with its
date and author, so that afterwards nobody can alter that record.

> # **This is a work in progress, not yet finished. Please come back later**




The example contract, [`contracts/PaymentRegistry.sol`](contracts/PaymentRegistry.sol),
stores payment receipts. For each record it keeps:

| Field | What it is for |
|---|---|
| `fileHash` | the file's fingerprint (e.g. SHA-256). Identifies the content without publishing it |
| `fileURL` | where the actual file lives (IPFS, Arweave, a server…) |
| `timestamp` | when it was recorded, set by the network itself |
| `payer` | who recorded it, set by the network itself |

The key idea: **the file itself is never uploaded to the blockchain** (it would be
expensive and public). What goes on-chain is its hash, which is small and is
enough to later prove the file has not changed.

## Requirements

- [Node.js](https://nodejs.org/) 18 or newer (tested on 24).
- Nothing else. **You need no money, no account anywhere, and no keys** to follow
  Route A below.

```bash
npm install
```

You will not find a Solidity package in `package.json`: the compiler is chosen by
the `solidity: "0.8.28"` line in [`hardhat.config.js`](hardhat.config.js), and
Hardhat downloads the right binary the first time you compile.

## Route A — everything local, no keys, no cost

This is how to start. Hardhat ships a **simulated blockchain** that runs on your
own machine: the same virtual machine Ethereum uses, but with toy accounts that
already hold 10,000 fake ETH.

```bash
npm run node:start        # start the simulated blockchain (in the background)
npm run deploy:local      # deploy the contract -> prints its address
```

Copy the address it prints and use it to interact:

```bash
CONTRACT_ADDRESS=0x5FbDB2315678afecb367f032d93F642f64180aa3 npm run interact:local
```

Actual output of that command:

```
Using account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

Registering payment...
  Transaction sent: 0xaca67e89dc6d341721b91062433b69bc39ef46b143677e337ec613d00827b921
  Confirmed in block 2 - gas used: 230616

Payments registered by 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266: 1
  [0] 2026-08-21T14:49:37.000Z
       hash: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
       url:  ipfs://QmExampleHashForThisTutorial
       payer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

You can register your own data with two extra variables:

```bash
CONTRACT_ADDRESS=0x5FbD... \
FILE_HASH=$(shasum -a 256 my-invoice.pdf | cut -d' ' -f1) \
FILE_URL=ipfs://QmWhatever \
  npm run interact:local
```

And when you are done:

```bash
npm run node:stop         # stop the simulated blockchain
```

> Shortcut: `npm run deploy` (without `:local`) deploys to a simulated blockchain
> that is born and dies with the command itself, so it **does not need**
> `node:start`. Handy to check that the contract deploys, but since it disappears
> straight away you cannot interact with it afterwards.

### The test accounts are not secret

On start-up, the local node warns you about this:

```
WARNING: These accounts, and their private keys, are publicly known.
Any funds sent to them on Mainnet or any other live network WILL BE LOST.

Account #0: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
Private Key: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

That private key belongs to everyone who installs Hardhat: it comes from a public
seed phrase. It is fine for practising, and **never** for holding anything of
value.

## Route B — the Sepolia testnet

Sepolia is a *real* test blockchain: public, distributed, with its own validators,
but where ETH is worthless. This route does need credentials.

```bash
cp .env.example .env
```

Then fill in `.env`:

- `ALCHEMY_API_URL` — the HTTPS URL of an [Alchemy](https://www.alchemy.com/) app
  pointing at Sepolia. Alchemy is "the AWS of blockchains": it saves you from
  running your own node.
- `PRIVATE_KEY` — the private key of a **throwaway test account**. Never one
  holding real funds.

You will also need some test ETH, which you get from a *faucet* — see below.

```bash
npm run deploy:sepolia
CONTRACT_ADDRESS=0x... npm run interact:sepolia
```

### Test ETH is free, and worthless on purpose

Sepolia ETH costs nothing. You request it from a faucet, which drips a small
amount into your address for free. It cannot be exchanged for real money, and
that is the whole point: if test ETH had value, nobody could hand it out freely
and the testnet would stop being a place to make mistakes safely.

**Never pay for test ETH.** Anyone selling it is running a scam — the currency is
deliberately worthless.

How much you need is tiny. Measured on this project:

| Operation | Gas |
|---|---|
| deploy `PaymentRegistry` | ~938,000 |
| one `registerPayment` call | ~231,000 |
| reading with `getPayments` | 0 |

At a typical Sepolia gas price that is well under 0.01 ETH per deployment, and a
single faucet drip (usually somewhere between 0.05 and 0.5 ETH) covers dozens of
deployments.

The friction is not the cost, it is the anti-abuse checks. Faucets are constantly
drained by bots, so most of them ask for something: an account with the provider,
a social login, a minimum balance on Ethereum mainnet, or a wait between
requests. Those rules change often, so treat any specific list as a starting
point rather than gospel:

- **[Google Cloud Web3 faucet](https://cloud.google.com/application/web3/faucet/ethereum/sepolia)** — asks for a Google account.
- **[Alchemy's faucet](https://www.alchemy.com/faucets/ethereum-sepolia)** — convenient if you already made an Alchemy account for `ALCHEMY_API_URL`.
- **[pk910's PoW faucet](https://sepolia-faucet.pk910.de/)** — no account at all; your browser mines for a few minutes instead.

If one refuses you, try another. And request into your **throwaway** test
account, never a wallet holding real funds.

`.env` is in `.gitignore` and must never be committed. If something is missing,
the project tells you plainly instead of failing with a cryptic error:

```
Cannot use the Sepolia network: ALCHEMY_API_URL and PRIVATE_KEY missing from your .env file

  1. Copy the template:   cp .env.example .env
  ...
```

> Note: Route A has been run and verified end to end. Route B has **not** been
> tested with real credentials.

## Available commands

| Script | What it does |
|---|---|
| `npm run compile` | compiles the contracts in `contracts/` |
| `npm run clean` | deletes `artifacts/` and `cache/` |
| `npm run node` | simulated blockchain in the foreground (occupies the terminal, Ctrl+C to stop) |
| `npm run node:start` | simulated blockchain in the background, log in `hardhat_node.log` |
| `npm run node:stop` | stops the simulated blockchain |
| `npm run deploy` | deploys to a single-use blockchain — no `node:start` needed |
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

To pass flags through to Hardhat you need the double dash:
`npm run compile -- --force`.

## Why a blockchain at all: state changes vs code changes

Once a contract is deployed, its code is **immutable**. There is no command that
edits a live contract. This is the single most important idea in the project, and
it is worth being precise about what can and cannot change.

**The state can change.** Every `registerPayment` call appends a record to the
contract's storage. That is not modifying the contract, that is using it.

**The code cannot.** If you edit `PaymentRegistry.sol` and deploy again, you get a
*different contract at a different address*. The old one stays exactly where it
was, with its data intact and its old logic running forever. Locally that
redeployment is free and you will do it constantly while developing. On a real
network it costs money, and anyone who knew the old address has to be told about
the new one.

### That limitation is the entire point

It is tempting to see immutability as a missing feature. For a registry of proofs
it is the feature.

Consider what a record in this contract is actually worth. Its value comes from a
stranger being able to check it and conclude: *nobody could have altered this
after the fact.* The moment somebody — you included — can rewrite the rules, that
conclusion evaporates. A record you can edit is just a database row, and a
database does not need a blockchain.

[`PaymentRegistry.sol`](contracts/PaymentRegistry.sol) gets this right. It has no
owner, no admin function, no way to delete or edit an existing record. It only
appends and reads. The absence of those features is what makes it trustworthy.

### If you genuinely need to change the logic later

There are established patterns, and they are worth knowing even if you do not use
them here:

- **Separate data from logic** — one contract stores, another one reasons. You
  replace the logic contract and keep the accumulated data.
- **Proxy pattern** (upgradeable contracts) — users always call one fixed
  address, a *proxy*, which forwards calls via `delegatecall` to an
  implementation contract you can swap out. OpenZeppelin's UUPS and Transparent
  proxies do this.

Both come with the same catch: they require a privileged key that can change the
rules after deployment. For a payments ledger or a game that may be an acceptable
trade. For a proof-of-record system it quietly destroys the guarantee you were
selling. Choose it deliberately, not by default.

### And a warning about Route A

A record written to your local Hardhat network proves nothing to anybody. It
exists only on your machine and vanishes with `npm run node:stop`. The local
network is for *developing* the contract; a proof that anyone else can verify
needs a public network.

## How it works under the hood

### The code *is* checked before deploying

Solidity is a **compiled, statically typed** language. Syntax and type errors show
up in `npm run compile`, long before you spend a single unit of gas:

```
TypeError: Return argument type string memory is not implicitly convertible to expected type uint256.
 --> contracts/Example.sol:7:16
Error HH600: Compilation failed
```

What the compiler does **not** catch: logic errors, a `require` that trips at
runtime, or excessive gas consumption. Those need tests.

### From `.sol` to the blockchain

Compiling produces one file per contract under `artifacts/`:

```
artifacts/contracts/PaymentRegistry.sol/PaymentRegistry.json
```

It holds the two things needed to deploy:

- **`abi`** — the index of the contract's functions and events. It tells
  JavaScript how to encode each call.
- **`bytecode`** — the EVM machine code that gets uploaded to the network.

When [`scripts/deploy.js`](scripts/deploy.js) calls
`getContractFactory("PaymentRegistry")` it **does not read the `.sol` file**: it
reads that JSON. And the lookup is **by contract name, not by file name** — that
string matches `contract PaymentRegistry` inside the `.sol`. Get it wrong and you
see:

```
HH700: Artifact for contract "NoSuchContract" not found.
```

You never need to compile by hand: `npm run deploy` compiles first if anything
changed.

### Writing costs gas, reading is free

[`scripts/interact.js`](scripts/interact.js) makes two very different kinds of
call:

- `registerPayment(...)` **changes network state**: it creates a transaction, it
  must be signed, it costs gas, and you must wait for it to be mined
  (`tx.wait()`).
- `getPayments(...)` is **read-only** (`view` in Solidity): no transaction, no
  cost, and it answers instantly.

Running the same registration twice in a row makes the storage cost visible:
**230,616** gas the first time and **213,516** the second. The 17,100 difference
is exactly the gap between writing to a storage slot that was zero (20,000 gas)
and modifying one already in use (2,900) — here, the array's length counter.

Be careful comparing gas across different inputs, though: a shorter `fileHash`
or `fileURL` occupies fewer storage slots and changes the total far more than
that effect does.

### ethers v5 vs v6

Much of the material online uses **ethers v5**, while this project uses **v6**.
It is the single most common thing beginners get stuck on:

| Concept | ethers v5 | ethers v6 (this project) |
|---|---|---|
| wait for deployment | `await contract.deployed()` | `await contract.waitForDeployment()` |
| read the address | `contract.address` | `await contract.getAddress()` |
| `uint256` values | `BigNumber` objects | native JavaScript `BigInt` |

If you see `TypeError: contract.deployed is not a function`, you are following a
v5 tutorial with v6 installed.

One important detail: `deploy()` returns as soon as the transaction is *sent*, not
mined. That is why you must wait with `waitForDeployment()`. Locally you never
notice, because mining is instant, but on a real network the script could finish
before the contract exists.

## Links

- [Official Hardhat tutorial](https://hardhat.org/tutorial)
- [How to deploy a smart contract to Sepolia (Alchemy)](https://docs.alchemy.com/docs/how-to-deploy-a-smart-contract-to-the-sepolia-testnet)

## Concepts

- Sepolia: testnet
- Alchemy (and Infura, QuickNode?): the "AWS" of blockchain. Saves you from having to run a node
- L2 (layer 2): Optimism, Arbitrum, zkSync, Polygon zkEVM and Polygon Miden:
  - They run on top of Ethereum, and depend entirely on Ethereum for their security
  - They batch and process transactions off mainnet, then send the information back to Ethereum.
  - Contract data and transactions live on the L2. Only a validity proof or a state summary is stored on Ethereum L1.
  - They use ETH for gas, because transactions eventually settle on Ethereum.
  - They are cheaper thanks to one key trick: batching many transactions into a single one before sending it to Ethereum.
    - Optimistic Rollups (Optimism, Arbitrum): assume transactions are valid unless someone proves otherwise. They have a waiting period (~7 days) for disputes.
    - ZK-Rollups (zkSync, Polygon zkEVM): use cryptographic proofs that guarantee transactions are valid with no waiting period.
- Sidechain: Polygon PoS
  - A separate blockchain with its own consensus and security (its own validators), though connected to Ethereum.
  - Uses MATIC for gas.
  - More independence, even faster and cheaper transactions.
  - On a sidechain, transaction data stays on the sidechain and is not published to Ethereum.
  - The connection only handles token conversions through a bridge, not the transactions themselves.
- If you launch a dApp, you have to choose which network to deploy it on:
  - Maximum security: Ethereum mainnet (expensive, but rock solid).
  - Scalability with Ethereum's security: Optimism, Arbitrum, zkSync or Polygon zkEVM.
  - Top speed and ultra-low cost: Polygon PoS, accepting that it does not inherit Ethereum's security.

## To do

- There are no tests (`npm test` is still unconfigured and there is no `test/`
  directory). In a project about irreversible records, showing how to test before
  deploying matters.
- The Sepolia route is written but not verified with real credentials.
