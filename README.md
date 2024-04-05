# automation-protocol

## Setup

Create `.env` (public values) and `.env.local` (secret values) files in root directory with templates below:

```
# .env file

# USDC contract address
USDC_CONTRACT_ADDRESS=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

# Rich USDC wallet address
UNLUCKY_USER_USDC_WALLET_ADDRESS=0x28C6c06298d514Db089934071355E5743bf21d60

# Amount of USDC on unlucky user wallet
UNLUCKY_USER_USDC_TRANSFER_AMOUNT=570639343061169

# Ethereum mainnet fork block number
BLOCK_NUMBER=19591777
```

```
# .env.local file

# Alchemy API key
ALCHEMY_PRIVATE_API_KEY=
```

## Installation

Install [`getfoundry`](https://book.getfoundry.sh/getting-started/installation) CLI:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

Install the latest precompiled binaries (`forge`, `cast`, `anvil`):

```bash
foundryup
```

Install all protocol required dependencies:

```bash
forge install
```

## Run

Firstly, run script to fork mainnet (you need to have this script running):

```bash
./scripts/fork-mainnet.sh
```

Next step will make all mock actions (impersonate rich wallet, make transfers and deploy smart contract):

```bash
./scripts/mock-actions.sh
```

## Commands

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

## Documentation

https://book.getfoundry.sh/
