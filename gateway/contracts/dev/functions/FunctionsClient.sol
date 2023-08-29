// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Functions.sol";
import "../interfaces/FunctionsClientInterface.sol";
import "../interfaces/FunctionsOracleInterface.sol";
import "./registry.sol";
import "./baseManager.sol";
import "./selector.sol";
/**
 * @title The Functions client contract
 * @notice Contract writers can inherit this contract in order to create Functions requests
 */
abstract contract FunctionsClient is FunctionsClientInterface{
  FunctionsOracleInterface internal s_oracle;
  mapping(bytes32 => address) internal s_pendingRequests;

  event RequestSent(bytes32 indexed id, bytes32 indexed functionId, address func);
  event RequestFulfilled(bytes32 indexed id,address indexed node, uint score,bytes result, bytes err);

  error SenderIsNotRegistry();
  error EmptyRequestData();
  error RequestIsAlreadyPending();

  Registry private reg;

  constructor(address oracle, Registry _reg) {
    setOracle(oracle);
        reg = _reg;
  }

  /**
   * @notice Sets the stored Oracle address
   * @param oracle The address of Functions Oracle contract
   */
  function setOracle(address oracle) public {
    s_oracle = FunctionsOracleInterface(oracle);
  }

  /**
   * @notice Sends a Functions request to the stored oracle address
   * @param req The initialized Functions.Request
   * @return requestId The generated request ID
   */
  function sendRequest(
    Functions.Request memory req
  ) internal returns (bytes32) {
    //TODO: check req
    address managerAddr = reg.manager(req.functionName);

    require(managerAddr != address(0x0), "not found manager");

    BaseManager m = BaseManager(managerAddr);

    uint memberCounts = m.getMembersCounts();
    
    require(memberCounts != 0, "member count is 0");

    bytes32 requestId = s_oracle.sendRequest(req.functionName, Functions.encodeCBOR(req));
    
    s_pendingRequests[requestId] = address(s_oracle);
    
    emit RequestSent(requestId, req.functionName, managerAddr);
    
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
    address node,
    uint score,
    bytes memory response,
    bytes memory err
  ) external override recordFulfillment(requestId) {
    fulfillRequest(requestId, response, err);

//    Functions.Response memory resp;
//    resp.initializeResponse( response, err);

//    s_oracle.fulfillRequestByNode(requestId,score,resp,err);
    
    emit RequestFulfilled(requestId, node,score,response, err);
  }

  /**
   * @dev Reverts if the sender is not the oracle that serviced the request.
   * Emits RequestFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordFulfillment(bytes32 requestId) {
    //  if (msg.sender != address(s_oracle)) {
    //    revert SenderIsNotRegistry();
    //  }
    // delete s_pendingRequests[requestId];
   
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
