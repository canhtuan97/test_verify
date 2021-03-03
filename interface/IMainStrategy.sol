pragma solidity 0.5.16;
interface IMainStrategy {
    function addStrategy(address[] calldata _strategies, address[] calldata _bridgeStrategies, uint256[] calldata _weights) external;

    function setWeight(address[] calldata _strategy, uint256[] calldata _weight) external;
}