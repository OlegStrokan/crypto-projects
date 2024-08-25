## Payment Channel

### This contract is simulation of defi market

#### Info:

Alice, a wholesale seller of Holi-themed items, has been explaining the benefits of a Simple Payment Channel to local shopkeepers in HoliVille. These shopkeepers visit Alice's warehouse to purchase Holi-themed costumes, masks, and other accessories for their shops. The process of purchasing these items can be cumbersome and time-consuming, especially when dealing with multiple shopkeepers.

Alice explained how a customer, John, who owns a local shop in HoliVille, would deposit 100 wei into the smart contract. John lists payments for a variety of Holi-themed items, such as costumes (10 wei each) and masks (20 wei each). When John closes the channel, the total amount of 30 wei is transferred to Alice for the items purchased, and the remaining 70 wei is transferred back to John. This process, Alice explained, would make transactions faster, more convenient, and more cost-effective for both Alice and the local shopkeepers in HoliVille.

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
