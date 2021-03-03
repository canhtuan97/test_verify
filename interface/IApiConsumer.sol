pragma solidity 0.5.16;
interface IApiConsumer {
    function requestData(bytes calldata data, bytes4 callbackFunctionId, address callbackAddress) external returns (bytes32 requestId);
}