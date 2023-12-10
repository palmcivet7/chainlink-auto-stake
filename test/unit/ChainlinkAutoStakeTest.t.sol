// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {DeployChainlinkAutoStake} from "../../script/DeployChainlinkAutoStake.s.sol";
import {ChainlinkAutoStake} from "../../src/ChainlinkAutoStake.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {MockLinkToken} from "@chainlink/contracts/src/v0.8/mocks/MockLinkToken.sol";
import {AutomationBase} from "@chainlink/contracts/src/v0.8/automation/AutomationBase.sol";
import {MockStakingPool} from "../mocks/MockStakingPool.sol";

contract ChainlinkAutoStakeTest is Test {
    ChainlinkAutoStake autoStake;
    HelperConfig helperConfig;
    address linkAddress;
    address stakingAddress;

    address public USER = makeAddr("USER");
    uint256 public USER_BALANCE = 1000 ether; // 1000 LINK

    function setUp() public {
        DeployChainlinkAutoStake deployer = new DeployChainlinkAutoStake();
        (autoStake, helperConfig) = deployer.run();
        (linkAddress, stakingAddress) = helperConfig.activeNetworkConfig();
        MockLinkToken(linkAddress).setBalance(msg.sender, USER_BALANCE);
    }

    function testConstructorSetsValuesCorrectly() public {
        assertEq(address(autoStake.i_link()), linkAddress);
        assertEq(address(autoStake.i_stakingContract()), stakingAddress);
    }

    ////////////////////////
    ////// Modifiers //////
    //////////////////////

    modifier fundContractWithLink() {
        vm.startPrank(msg.sender);
        MockLinkToken(linkAddress).transfer(address(autoStake), USER_BALANCE);
        vm.stopPrank();
        _;
    }

    modifier setTotalPrincipalWithSpace() {
        vm.startPrank(0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        MockStakingPool(stakingAddress).setTotalPrincipal(40874500000000000000000000);
        vm.stopPrank();
        _;
    }

    modifier fundStakingPoolWithLink() {
        vm.startPrank(msg.sender);
        MockLinkToken(linkAddress).transfer(address(stakingAddress), USER_BALANCE);
        vm.stopPrank();
        _;
    }

    modifier setTotalPrincipalToMax() {
        vm.startPrank(0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        MockStakingPool(stakingAddress).setTotalPrincipal(40875000000000000000000000);
        vm.stopPrank();
        _;
    }

    ////////////////////////
    ////// checkUpkeep ////
    //////////////////////

    function testCheckUpkeepCannotExecute() public {
        vm.startPrank(USER);
        vm.expectRevert(AutomationBase.OnlySimulatedBackend.selector);
        autoStake.checkUpkeep("");
        vm.stopPrank();
    }

    //////////////////////////
    ////// performUpkeep ////
    ////////////////////////

    function testPerformUpkeepStakesFullBalance() public fundContractWithLink {
        vm.startPrank(USER);
        uint256 autoStakeStartingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        uint256 stakingPoolStartingBalance = MockLinkToken(linkAddress).balanceOf(address(stakingAddress));
        autoStake.performUpkeep("");
        uint256 autoStakeEndingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        uint256 stakingPoolEndingBalance = MockLinkToken(linkAddress).balanceOf(address(stakingAddress));
        vm.stopPrank();
        assertEq(autoStakeStartingBalance, stakingPoolEndingBalance);
        assertEq(stakingPoolStartingBalance, autoStakeEndingBalance);
    }

    function testPerformUpkeepStakesAvailableSpace() public fundContractWithLink setTotalPrincipalWithSpace {
        vm.startPrank(USER);
        uint256 autoStakeStartingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        uint256 stakingPoolStartingBalance = MockLinkToken(linkAddress).balanceOf(address(stakingAddress));
        uint256 availableSpace =
            MockStakingPool(stakingAddress).getMaxPoolSize() - MockStakingPool(stakingAddress).getTotalPrincipal();

        autoStake.performUpkeep("");
        uint256 autoStakeEndingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        uint256 stakingPoolEndingBalance = MockLinkToken(linkAddress).balanceOf(address(stakingAddress));
        vm.stopPrank();
        assertEq(autoStakeEndingBalance, autoStakeStartingBalance - availableSpace);
        assertEq(stakingPoolEndingBalance, stakingPoolStartingBalance + availableSpace);
    }

    function testPerformUpkeepRevertsIfNoLinkDeposited() public {
        vm.startPrank(msg.sender);
        vm.expectRevert(ChainlinkAutoStake.ChainlinkAutoStake__NoLinkToDeposit.selector);
        autoStake.performUpkeep("");
        vm.stopPrank();
    }

    function testPerformUpkeepRevertsIfNoSpaceInPool() public fundContractWithLink setTotalPrincipalToMax {
        vm.startPrank(msg.sender);
        vm.expectRevert(ChainlinkAutoStake.ChainlinkAutoStake__NoSpaceInPool.selector);
        autoStake.performUpkeep("");
        vm.stopPrank();
    }

    //////////////////////////
    /////// Withdraw ////////
    ////////////////////////

    function testMigrateWorks() public {
        vm.startPrank(msg.sender);
        autoStake.migrate("");
        vm.stopPrank();
    }

    function testMigrateRevertsIfNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        autoStake.migrate("");
        vm.stopPrank();
    }

    function testUnstakeWorks() public fundStakingPoolWithLink {
        vm.startPrank(msg.sender);
        uint256 poolStartingBalance = MockLinkToken(linkAddress).balanceOf(address(stakingAddress));
        uint256 contractStartingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        autoStake.unstake(USER_BALANCE);
        uint256 poolEndingBalance = MockLinkToken(linkAddress).balanceOf(address(stakingAddress));
        uint256 contractEndingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        vm.stopPrank();
        assertEq(poolStartingBalance, contractEndingBalance);
        assertEq(contractStartingBalance, poolEndingBalance);
    }

    function testUnstakeRevertsIfNotOwner() public {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        autoStake.unstake(USER_BALANCE);
        vm.stopPrank();
    }

    function testWithdrawWorks() public fundContractWithLink {
        vm.startPrank(msg.sender);
        uint256 ownerStartingBalance = MockLinkToken(linkAddress).balanceOf(msg.sender);
        uint256 contractStartingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        autoStake.withdrawLink();
        uint256 ownerEndingBalance = MockLinkToken(linkAddress).balanceOf(msg.sender);
        uint256 contractEndingBalance = MockLinkToken(linkAddress).balanceOf(address(autoStake));
        vm.stopPrank();
        assertEq(ownerStartingBalance, contractEndingBalance);
        assertEq(contractStartingBalance, ownerEndingBalance);
    }

    function testWithdrawRevertsIfNotOwner() public fundContractWithLink {
        vm.startPrank(USER);
        vm.expectRevert("Ownable: caller is not the owner");
        autoStake.withdrawLink();
        vm.stopPrank();
    }

    function testWithdrawRevertsIfNotBalance() public {
        vm.startPrank(msg.sender);
        vm.expectRevert(ChainlinkAutoStake.ChainlinkAutoStake__NoLinkToWithdraw.selector);
        autoStake.withdrawLink();
        vm.stopPrank();
    }
}
