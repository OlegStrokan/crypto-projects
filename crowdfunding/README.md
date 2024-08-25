## CrowdFunding

### This contract is simulation of real crowdfunding

#### Specs:

- Anyone can create a new campaign by specifying the goal amount (in USD), and the duration.
- Any user, except for the creator of the campaign, can donate to any campaign using the token.
- Users can cancel their donations anytime for a particular campaign before the deadline has passed.
- If after the deadline has passed, the goal has not been reached, the campaign is said to be unsuccessful and donors can get their contributions back.

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
