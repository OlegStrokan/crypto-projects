## Stacking

### This contract is simulation of defi stacking mechanism

#### Info:

Staking contracts allows users to stake tokens for a specific duration and earn rewards based on their staking period.

The calculation of the rewards is done in the following manner:

- If less than 1 day has been passed, the user earns no rewards.
- If more than 1 day has been passed, the user earns 1% on their staked token amount.
- If more than a week has passed, the user earns 10%.
- If more than a month (30 days) has been passed, the user earns 50%.

## Documentation

https://book.getfoundry.sh/

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
