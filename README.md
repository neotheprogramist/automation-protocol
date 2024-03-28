# automation-protocol

## Setup

Create `.env` (public values) and `.env.local` (secret values) files in root directory with templates below:

```
# .env file

USDC_CONTRACT_ADDRESS=
FIRST_ANVIL_WALLET_ADDRESS_ALICE=
UNLUCKY_USER_USDC_WALLET_ADDRESS=
```

```
# .env.local file

ALCHEMY_PRIVATE_API_KEY=
```

## Run

## Usage

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
