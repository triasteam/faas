// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/FunctionsOracleInterface.sol";
import "./selector.sol";
import "./registry.sol";
/**
 * @title Functions Oracle contract
 * @notice Contract that nodes of a Decentralized Oracle Network (DON) interact with
 * @dev THIS CONTRACT HAS NOT GONE THROUGH ANY SECURITY REVIEW. DO NOT USE IN PROD.
 */
contract FunctionsOracle is FunctionsOracleInterface {
  event OracleRequest(
    bytes32 indexed requestId,
    address requestingContract,
    address requestInitiator,
    bytes32 indexed subscriptionId,
    address subscriptionOwner,
    bytes data
  );
  event OracleResponse(bytes32 indexed requestId);
  // event UserCallbackError(bytes32 indexed requestId, string reason);
  // event UserCallbackRawError(bytes32 indexed requestId, bytes lowLevelData);
  // event InvalidRequestID(bytes32 indexed requestId);

  error EmptyRequestData();
  error InconsistentReportData();
  error EmptyPublicKey();
  error EmptyBillingRegistry();
  error UnauthorizedPublicKeyChange();

  struct responseInfo {
    address node;
    uint score;
    bytes resp;
  }

  uint256 constant public EXPIRY_TIME = 5 minutes;
  mapping(bytes32 => mapping(address => bool)) private allowedOracles;
  //  mapping(bytes32 => Callback) private callbacks;//requestId
  mapping(bytes32 => mapping(address => responseInfo)) private functionResponse;//requestId => node address => responseInfo
  mapping(bytes32 => uint) private requestBirth; // request birth

  Selector private selector;
  Registry private reg;


  function init() public {
    selector = 0x0000000000000000000000000000000000002005;
    reg = 0x0000000000000000000000000000000000002003;

  }
  
  function sendRequest(
    bytes32 functionId,
    bytes calldata data
  ) external override returns (bytes32) {

    if (data.length == 0) {
      revert EmptyRequestData();
    }

    bytes32 requestId = computeRequestId(msg.sender,tx.origin, functionId, 0);

    emit OracleRequest(
      requestId,
      msg.sender,
      tx.origin,
      functionId,
      address(0x0),
      data
    );
    requestBirth[requestId]=block.timestamp;
    return requestId;
  }

  /**
   * @notice Called by the node to fulfill requests
   * @dev Response must have a valid callback, and will delete the associated callback storage
   * before calling the external contract.
   * @param _requestId The fulfillment request ID that must match the requester's
   * @param _data The data to return to the consuming contract
   * @return Status if the external call was successful
   */

  function fulfillRequestByNode(
    bytes32 _requestId,
    uint score,
    bytes _data
  ) external isValidRequest(_requestId) returns (bool) {
    uint birth = requestBirth[_requestId];

    if (birth + EXPIRY_TIME < block.timestamp){
      revert("function request timeout");
    }

    responseInfo memory resp = responseInfo(msg.sender,score,_data);

    functionResponse[_requestId][tx.origin]=resp;

    return true;
  }

  function fulfillOracleRequest() public  returns (bool) {

   //TODO:

    return true;
  }

  /**
   * @dev Reverts if request ID does not exist
   * @param _requestId The given request ID to check in stored `callbacks`
   */
  modifier isValidRequest(bytes32 _requestId) {
    require(requestBirth[_requestId] != 0, "Must have a valid requestId");

    address managerAddr = reg.manager(req.functionName);

    require(managerAddr != address(0x0), "not found manager");

    BaseManager m = BaseManager(managerAddr);
    bytes32 name =   m.getName(addr);

    require(name != bytes32(0x0), "selected node unregistered");
    _;
  }


  function computeRequestId(
    address nodeAddr,
    address client,
    bytes32 subscriptionId,
    uint64 nonce
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(nodeAddr, client, subscriptionId, nonce));
  }

}
