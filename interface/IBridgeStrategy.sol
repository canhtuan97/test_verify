pragma solidity 0.5.16;

interface IBridgeStrategy {

    function underlying(address strategy) external view returns (address);

    function vault(address strategy) external view returns (address);

    function withdrawAllToVault(address strategy) external;

    function withdrawToVault(address strategy, uint256 amount) external;

    function investedUnderlyingBalance(address strategy) external view returns (uint256); // itsNotMuch()

    function doHardWork(address strategy) external;

    function depositArbCheck(address strategy) external view returns (bool);

}