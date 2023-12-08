// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {MockStakingPool} from "../test/mocks/MockStakingPool.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployMockStakingPool is Script {
    function run() external returns (MockStakingPool, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (address link,) = config.activeNetworkConfig();

        vm.startBroadcast();
        MockStakingPool stakingPool = new MockStakingPool(link);
        vm.stopBroadcast();
        return (stakingPool, config);
    }
}
