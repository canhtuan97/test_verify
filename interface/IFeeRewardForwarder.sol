pragma solidity 0.5.16;
interface IFeeRewardForwarder {

    function setTokenPool(address _pool) external;


    function setConversionPath(address from, address to, address[] calldata _uniswapRoute) external;

    // Transfers the funds from the msg.sender to the pool
    // under normal circumstances, msg.sender is the strategy
    function poolNotifyFixedTarget(address _token, uint256 _amount) external;
}