// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {MockStakingPool} from "../test/mocks/MockStakingPool.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        address link;
        address staking;
    }

    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({link: 0x779877A7B0D9E8603169DdbD7836e478b4624789, staking: address(0)});
    }

    function getMainnetConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({
            link: 0x514910771AF9Ca656af840dff83E8264EcF986CA,
            staking: 0xBc10f2E862ED4502144c7d632a3459F49DFCDB5e
        });
    }

    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        MockLinkToken mockLink = new MockLinkToken();
        MockStakingPool mockStakingPool = new MockStakingPool(address(mockLink));
        return NetworkConfig({link: address(mockLink), staking: address(mockStakingPool)});
    }
}
