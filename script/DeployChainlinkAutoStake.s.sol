// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {ChainlinkAutoStake} from "../src/ChainlinkAutoStake.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployChainlinkAutoStake is Script {
    function run() external returns (ChainlinkAutoStake, HelperConfig) {
        HelperConfig config = new HelperConfig();
        (address link, address staking) = config.activeNetworkConfig();

        vm.startBroadcast();
        ChainlinkAutoStake autoStake = new ChainlinkAutoStake(link, staking);
        vm.stopBroadcast();
        return (autoStake, config);
    }
}
