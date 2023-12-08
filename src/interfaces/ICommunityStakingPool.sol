// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICommunityStakingPool {
    // Function to get the maximum amount that can be staked in the pool
    function getMaxPoolSize() external view returns (uint256);

    // Function to get the total principal staked in the pool
    function getTotalPrincipal() external view returns (uint256);

    /**
     * @notice Unstakes a specified amount of LINK tokens from the staking pool.
     * @param _amount The amount of LINK tokens to unstake.
     */
    function unstake(uint256 _amount) external;
}
