// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICommunityStakingPool.sol";

/**
 * @author palmcivet
 * @title Chainlink Auto Stake
 *
 * @notice This contract monitors withdrawals from the Chainlink Community Staking Pool contract
 * and then uses Chainlink Automation to deposit into it.
 */
contract ChainlinkAutoStake is Ownable, AutomationCompatible {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error ChainlinkAutoStake__OnlyForwarder();
    error ChainlinkAutoStake__NoLinkToDeposit();
    error ChainlinkAutoStake__NoSpaceInPool();
    error ChainlinkAutoStake__NoLinkToWithdraw();
    error ChainlinkAutoStake__LinkTransferFailed();

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/
    LinkTokenInterface internal immutable i_link;
    ICommunityStakingPool internal immutable i_stakingContract;

    address internal s_forwarder;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _linkTokenAddress, address _stakingContractAddress) {
        i_link = LinkTokenInterface(_linkTokenAddress);
        i_stakingContract = ICommunityStakingPool(_stakingContractAddress);
    }

    /*//////////////////////////////////////////////////////////////
                               AUTOMATION
    //////////////////////////////////////////////////////////////*/
    function checkUpkeep(bytes calldata /* checkData */ )
        external
        view
        cannotExecute
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        upkeepNeeded = i_stakingContract.getTotalPrincipal() < i_stakingContract.getMaxPoolSize();
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        if (msg.sender != s_forwarder) revert ChainlinkAutoStake__OnlyForwarder();

        uint256 balance = i_link.balanceOf(address(this));
        if (balance == 0) revert ChainlinkAutoStake__NoLinkToDeposit();
        uint256 availableSpace = i_stakingContract.getMaxPoolSize() - i_stakingContract.getTotalPrincipal();
        if (availableSpace == 0) revert ChainlinkAutoStake__NoSpaceInPool();
        if (availableSpace < balance) {
            i_link.transferAndCall(address(i_stakingContract), availableSpace, "");
        } else {
            i_link.transferAndCall(address(i_stakingContract), balance, "");
        }
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/
    function migrate(bytes calldata _data) external onlyOwner {
        i_stakingContract.migrate(_data);
    }

    function unstake(uint256 _amount) external onlyOwner {
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
