// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";


/**
 * @title Functions Consumer contract
 * @notice This contract is a demonstration of using Functions.
 * @notice NOT FOR PRODUCTION USE
 */
contract FunctionsConsumer is FunctionsClient {
  using Functions for Functions.Request;

  bytes32 public latestRequestId;
  bytes public latestResponse;
  bytes public latestError;

  event FuncResponse(bytes32 indexed requestId, bytes result, bytes err);

  constructor(address oracle) FunctionsClient(oracle)  {}
  /**
   * @notice Send a simple request
   *
   * @param source JavaScript source code
   * @param secrets Encrypted secrets payload
   * @param args List of arguments accessible from within the source code
   * @param subscriptionId Funtions billing subscription ID
   * @param gasLimit Maximum amount of gas used to call the client contract's `handleOracleFulfillment` function
   * @return Functions request ID
   */
  function executeRequest(
    string calldata source,
    bytes calldata secrets,
    string[] calldata args,
    uint64 subscriptionId,
    uint32 gasLimit
  ) public returns (bytes32) {
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
    if (secrets.length > 0) {
      req.addRemoteSecrets(secrets);
    }
    if (args.length > 0) req.addArgs(args);

    bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);(req, subscriptionId, gasLimit);
    latestRequestId = assignedReqID;
    return assignedReqID;
  }
  /**
  * @notice Callback that is invoked once the DON has resolved the request or hit an error
   *
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    latestResponse = response;
    latestError = err;
    emit FuncResponse(requestId, response, err);
  }
}
