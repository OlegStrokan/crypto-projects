// SPDX-license-Identifier: MIT
pragma solidity 0.8.10;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        address entryPoint;
    }

    uint256 constant ETHSEPOLIA_CHAIN_ID = 11155111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31337;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor () {
        networkConfig[ETHSEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
    }

    function getConfig() public returns(NetworkConfig memory) {
        getConfigByChainId(block.chainid)
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else if (networkConfigs[chainId].entryPoint != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({ ethryPoint: 00x0 });
    }

     function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({ entryPoint: address(0) });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if (localNetworkConfig.entryPoint != address(0)) {
            return localNetworkConfig;
        }

        // deploy a mock entry point contract...
    }

}