// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions oracle interface.
 */
interface FunctionsOracleInterface {
  function init() external;
  /**
   * @notice Sends a request (encoded as data) using the provided subscriptionId
   * @param functionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Functions request data, use FunctionsClient API to encode a request
   */
  function sendRequest(bytes32 functionId, bytes calldata data) external returns (bytes32);

  function fulfillOracleRequest() external returns (bool);

  function fulfillRequestByNode(bytes32 _requestId,
    uint score, 
    bytes calldata resp,
    bytes calldata err
    ) external returns (bool);
}
