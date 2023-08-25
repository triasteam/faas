// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import "../interfaces/FunctionsOracleInterface.sol";
import "./selector.sol";
import "./registry.sol";
import "../interfaces/FunctionsClientInterface.sol";

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
  event OracleRequestTimeout(bytes32 indexed requestId, string reason);
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
    address oracleAddress;
    uint score;
    bytes resp;
    bytes err;
  }

  struct requestBirth {
    bytes32 requestId;
    bytes32 functionId;
    uint birth;
  }

  uint256 constant public EXPIRY_TIME = 5 minutes;
  mapping(bytes32 => mapping(address => bool)) private allowedOracles;
  //  mapping(bytes32 => Callback) private callbacks;//requestId
  mapping(bytes32 => responseInfo[]) private functionResponse;//requestId => node address => responseInfo
  DoubleEndedQueue.Bytes32Deque reqQueen; // request birth
  mapping(bytes32 => requestBirth) reqMap;

  uint256[] public respSelector;

  Selector private selector;
  Registry private reg;


  function init() public {
    selector = Selector(0x0000000000000000000000000000000000002005);
    reg = Registry(0x0000000000000000000000000000000000002003);
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
    DoubleEndedQueue.pushBack(reqQueen,requestId);
    reqMap[requestId]=requestBirth(requestId,functionId,block.timestamp);
    return requestId;
  }

  /**
   * @notice Called by the node to fulfill requests
   * @dev Response must have a valid callback, and will delete the associated callback storage
   * before calling the external contract.
   * @param _requestId The fulfillment request ID that must match the requester's
   * @param oracleAddress oracle contract address
   * @param score node score that the execute function
   * @param resp node response
   * @param err node occurs error when to execute function
   * @return Status if the external call was successful
   */
  function fulfillRequestByNode(
    bytes32 _requestId,
    address oracleAddress,
    uint score,
    bytes calldata resp,
    bytes calldata err
  ) public override isValidRequest(_requestId) returns (bool) {
    uint birth = reqMap[_requestId].birth;

    if (birth + EXPIRY_TIME < block.timestamp){
      revert("function request timeout");
    }

    responseInfo memory respA = responseInfo(tx.origin,oracleAddress,score,resp,err);

    functionResponse[_requestId].push(respA);

    return true;
  }

  function fulfillOracleRequest() public  returns (bool) {

    uint256 vtfValue = selector.getVRF();
    respSelector = new uint[](5);

    while (DoubleEndedQueue.length(reqQueen) != 0) {

      bytes32 reqId = DoubleEndedQueue.popFront(reqQueen);

      requestBirth memory reqInfo = reqMap[reqId];
      bool isTimeout = reqInfo.birth + EXPIRY_TIME < block.timestamp;
      responseInfo[] memory respArr =functionResponse[reqId];

      if ( !isTimeout && respArr.length < 2) {
          continue;
      }

      if (isTimeout && respArr.length == 0) {
        emit OracleRequestTimeout(reqId,"not found response");
        continue;
      }

      if (isTimeout && respArr.length > 0) {
        for (uint ir = 0; ir < respArr.length; ir++) {
          bool isRight = respArr[ir].resp.length != 0;
          if (respSelector.length == 0 && isRight){
            respSelector.push(ir);
            continue;
          }

          if(respArr[respSelector[0]].score > respArr[ir].score) {
            continue;
          }

          if(respArr[respSelector[0]].score < respArr[ir].score && isRight) {
            respSelector = [ir];
          }

          if(respArr[respSelector[0]].score == respArr[ir].score && isRight) {
            respSelector.push(ir);
          }
        }
      }

      if(respSelector.length > 0) {
        responseInfo memory ret = respArr[respSelector[vtfValue % respSelector.length]];

        FunctionsClientInterface(ret.oracleAddress).handleOracleFulfillment(
          reqId,ret.node,ret.score,ret.resp,ret.err);
      }else{
        responseInfo memory ret = respArr[vtfValue % respArr.length];

        FunctionsClientInterface(ret.oracleAddress).handleOracleFulfillment(
          reqId,ret.node,ret.score,ret.resp,ret.err);
      }
      delete reqMap[reqId];

    }

    return true;
  }

  /**
   * @dev Reverts if request ID does not exist
   * @param _requestId The given request ID to check in stored `callbacks`
   */
  modifier isValidRequest(bytes32 _requestId) {

    require(reqMap[_requestId].birth != 0, "Must have a valid requestId");

//    address managerAddr = reg.manager(req.functionName);
//
//    require(managerAddr != address(0x0), "not found manager");
//
//    BaseManager m = BaseManager(managerAddr);
//    bytes32 name =   m.getName(msg.sender);
//
//    require(name != bytes32(0x0), "selected node unregistered");
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
