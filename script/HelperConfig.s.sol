//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// deploy mocks when we are on a local anvil chain
// keep track of contract address accross different chains

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/mockV3Aggregator.sol";

contract HelperConfig is Script {
    // if we are on a local anvil we deploy mocks
    //otherwise, grab te existing addrss from the live network

    struct NetworkConfig {
        address PriceFeed;
    }

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 20000e18;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({PriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306});  //why is this memory, ow does this corrolate to wrapping price feed addres with aggregator v3
        return sepoliaConfig;
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.PriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({PriceFeed: address(mockPriceFeed)});

        return anvilConfig;
    }
}
