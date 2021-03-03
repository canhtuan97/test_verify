pragma solidity 0.5.16;

interface IStrategy {

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    function doHardWork() external;

    function depositArbCheck() external view returns (bool);
}