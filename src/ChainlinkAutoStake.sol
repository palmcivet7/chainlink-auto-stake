// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICommunityStakingPool.sol";

/**
 * @author palmcivet
 * @title Chainlink Auto Stake
 * @notice This contract monitors withdrawals from the Chainlink Community Staking Pool contract
 * and then uses Chainlink Automation to deposit into it.
 */
contract ChainlinkAutoStake is Ownable, AutomationCompatible {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ChainlinkAutoStake__OnlyForwarder();
    error ChainlinkAutoStake__NoLinkToWithdraw();
    error ChainlinkAutoStake__LinkTransferFailed();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    LinkTokenInterface internal immutable i_link;
    ICommunityStakingPool internal immutable i_stakingContract;

    /// @dev automation forwarder contract unique to subscription
    address internal s_forwarder;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event LinkStaked(uint256 amount);
    event LinkUnstaked(uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _linkTokenAddress, address _stakingContractAddress) Ownable(msg.sender) {
        i_link = LinkTokenInterface(_linkTokenAddress);
        i_stakingContract = ICommunityStakingPool(_stakingContractAddress);
    }

    /*//////////////////////////////////////////////////////////////
                               AUTOMATION
    //////////////////////////////////////////////////////////////*/
    /// @dev called continuously offchain by automation nodes
    function checkUpkeep(bytes calldata)
        external
        view
        cannotExecute
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256 balance = i_link.balanceOf(address(this));
        uint256 availableSpace = i_stakingContract.getMaxPoolSize() - i_stakingContract.getTotalPrincipal();
        if (availableSpace < balance) performData = abi.encode(availableSpace);
        else performData = abi.encode(balance);

        upkeepNeeded = i_stakingContract.getTotalPrincipal() < i_stakingContract.getMaxPoolSize();
        return (upkeepNeeded, performData);
    }

    /// @dev called by automation forwarder to stake tokens when checkUpkeep returns true
    function performUpkeep(bytes calldata _performData) external {
        if (msg.sender != s_forwarder) revert ChainlinkAutoStake__OnlyForwarder();

        uint256 stakeAmount = abi.decode(_performData, (uint256));

        emit LinkStaked(stakeAmount);

        i_link.transferAndCall(address(i_stakingContract), stakeAmount, "");
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/
    /// @dev migrates to the next iteration of staking
    /// @notice staking contract would need to be updated and therefore not immutable
    function migrate(bytes calldata _data) external onlyOwner {
        i_stakingContract.migrate(_data);
    }

    /// @dev unstakes tokens from staking contract
    function unstake(uint256 _amount) external onlyOwner {
        emit LinkUnstaked(_amount);
        i_stakingContract.unstake(_amount);
    }

    function withdrawLink() external onlyOwner {
        uint256 balance = i_link.balanceOf(address(this));
        if (balance == 0) revert ChainlinkAutoStake__NoLinkToWithdraw();
        if (!i_link.transfer(msg.sender, balance)) revert ChainlinkAutoStake__LinkTransferFailed();
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTER
    //////////////////////////////////////////////////////////////*/
    function setForwarder(address _forwarder) external onlyOwner {
        s_forwarder = _forwarder;
    }

    /*//////////////////////////////////////////////////////////////
                                 GETTER
    //////////////////////////////////////////////////////////////*/
    function getLink() external view returns (LinkTokenInterface) {
        return i_link;
    }

    function getStakingPool() external view returns (ICommunityStakingPool) {
        return i_stakingContract;
    }
}
