// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Functions.sol";
import "../interfaces/FunctionsClientInterface.sol";
import "../interfaces/FunctionsOracleInterface.sol";
import "./registry.sol";
import "./baseManager.sol";
import "./selector.sol";
/**
 * @title The Chainlink Functions client contract
 * @notice Contract writers can inherit this contract in order to create Chainlink Functions requests
 */
abstract contract FunctionsClient is FunctionsClientInterface{
  FunctionsOracleInterface internal s_oracle;
  mapping(bytes32 => address) internal s_pendingRequests;

  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id,bytes result, bytes err);

  error SenderIsNotRegistry();
  error EmptyRequestData();
  error RequestIsAlreadyPending();

  Selector private selector;
  Registry private reg;

  constructor(address oracle,Selector _selector ,Registry _reg) {
    setOracle(oracle);
        reg = _reg;
        selector = _selector;
  }

  /**
   * @notice Sets the stored Oracle address
   * @param oracle The address of Functions Oracle contract
   */
  function setOracle(address oracle) internal {
    s_oracle = FunctionsOracleInterface(oracle);
  }

  /**
   * @notice Sends a Chainlink Functions request to the stored oracle address
   * @param req The initialized Functions.Request
   * @param gasLimit gas limit for the fulfillment callback
   * @return requestId The generated request ID
   */
  function sendRequest(
    Functions.Request memory req,
    uint32 gasLimit
  ) internal returns (bytes32) {

    uint vrfValue = selector.getVRF();
  
    address managerAddr = reg.manager(req.functionname);

    require(managerAddr != address(0x0),"not found manager");

    BaseManager m = BaseManager(managerAddr);

    address[] memory members = m.getBestMember();

    uint functionIndex = vrfValue % members.length;
    bytes32 name=   m.getName(members[functionIndex]);
    bytes32 requestId = s_oracle.sendRequest(name, Functions.encodeCBOR(req), gasLimit);
    
    s_pendingRequests[requestId] = tx.origin;
    
    emit RequestSent(requestId);
    
    return requestId;
  }

  
  /**
    * @notice User defined function to handle a response
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual;

  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external override recordFulfillment(requestId) {
    fulfillRequest(requestId, response, err);
    emit RequestFulfilled(requestId, response, err);
  }

  /**
   * @dev Reverts if the sender is not the oracle that serviced the request.
   * Emits RequestFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordFulfillment(bytes32 requestId) {
    if (msg.sender != s_pendingRequests[requestId]) {
      revert SenderIsNotRegistry();
    }
    delete s_pendingRequests[requestId];
   
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    if (s_pendingRequests[requestId] != address(0)) {
      revert RequestIsAlreadyPending();
    }
    _;
  }
}