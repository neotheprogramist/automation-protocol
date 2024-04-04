# automation-protocol

## Setup

Create `.env` (public values) and `.env.local` (secret values) files in root directory with templates below:

```
# .env file

USDC_CONTRACT_ADDRESS=
UNLUCKY_USER_USDC_WALLET_ADDRESS=
BLOCK_NUMBER=
```

```
# .env.local file

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

## Run

Firstly, run script to fork mainnet (you need to have this script running):

```bash
./scripts/fork-mainnet.sh
```

Next step will make all mock actions (impersonate rich wallet, make transfers and deploy smart contract):

```bash
./scripts/mock-actions.sh
```

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
