pragma solidity 0.5.16;
interface IVault {
    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy, address _bridgeStrategy) external;

    function getPricePerFullShare() external view returns (uint256);

    function investedTokenAmount() external view returns (uint256);

    function availableToInvestOut() external view returns (uint256);

    function doHardWork() external;

    function rebalance() external;
}