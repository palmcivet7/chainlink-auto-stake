// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";

contract MockStakingPool is Ownable {
    error MockStakingPool__TotalPrincipalCannotExceedMaxPoolSize();
    error MockStakingPool__NoLinkToWithdraw();
    error MockStakingPool__LinkTransferFailed();
    error MockStakingPool_InvalidAmount();

    LinkTokenInterface public immutable i_link;
    uint256 private totalPrincipal;

    constructor(address _linkTokenAddress) {
        i_link = LinkTokenInterface(_linkTokenAddress);
    }

    function setTotalPrincipal(uint256 _totalPrincipal) public onlyOwner {
        if (_totalPrincipal > getMaxPoolSize()) revert MockStakingPool__TotalPrincipalCannotExceedMaxPoolSize();
        totalPrincipal = _totalPrincipal;
    }

    function getMaxPoolSize() public pure returns (uint256) {
        return 40875000000000000000000000; // actual pool size https://etherscan.io/address/0xbc10f2e862ed4502144c7d632a3459f49dfcdb5e#readContract
    }

    function getTotalPrincipal() external view returns (uint256) {
        return totalPrincipal;
    }

    /**
     * @notice Unstakes a specified amount of LINK tokens from the staking pool.
     * @param _amount The amount of LINK tokens to unstake.
     */
    function unstake(uint256 _amount) external {
        uint256 balance = i_link.balanceOf(address(this));
        if (balance == 0) revert MockStakingPool__NoLinkToWithdraw();
        if (_amount > balance) revert MockStakingPool_InvalidAmount();
        if (!i_link.transfer(msg.sender, _amount)) revert MockStakingPool__LinkTransferFailed();
    }
}
