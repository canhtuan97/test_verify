pragma solidity 0.5.16;
interface IHardRewards {

    function rewardMe(address recipient, address vault) external;

    function addVault(address _vault) external;

    function removeVault(address _vault) external;

    function load(address _token, uint256 _rate, uint256 _amount) external;
}