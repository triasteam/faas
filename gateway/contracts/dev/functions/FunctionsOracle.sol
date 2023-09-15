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
    bytes32 indexed functionId,
    address subscriptionOwner,
    bytes data
  );
  event OracleResponse(bytes32 indexed requestId);
  event OracleRequestTimeout(bytes32 indexed requestId, uint birth, uint blockTime,string reason);
  event RequestFulfilled(bytes32 indexed id,address indexed node, uint score,bytes result, bytes err);
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
    bytes err;
  }

  struct requestBirth {
    bytes32 requestId;
    bytes32 functionId;
    uint birth;
    address msgSender;
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

    bytes32 requestId = computeRequestId(msg.sender, tx.origin, functionId, block.number);

    if (reqMap[requestId].birth != 0){
      return requestId;
    }

    emit OracleRequest(
      requestId,
      msg.sender,
      tx.origin,
      functionId,
      address(0x0),
      data
    );
    DoubleEndedQueue.pushBack(reqQueen,requestId);
    reqMap[requestId]=requestBirth(requestId, functionId, block.timestamp, msg.sender);
    return requestId;
  }

  function getReq(bytes32 requestId) public view returns(uint){
    return reqMap[requestId].birth;
  }

  /**
   * @notice Called by the node to fulfill requests
   * @dev Response must have a valid callback, and will delete the associated callback storage
   * before calling the external contract.
   * @param _requestId The fulfillment request ID that must match the requester's
   * @param score node score that the execute function
   * @param resp node response
   * @param err node occurs error when to execute function
   * @return Status if the external call was successful
   */
  function fulfillRequestByNode(
    bytes32 _requestId,
    uint score,
    bytes calldata resp,
    bytes calldata err
  ) public override isValidRequest(_requestId) returns (bool) {
    if (!isContract(msg.sender)){
        return false;
    }
    uint birth = reqMap[_requestId].birth;

    if (birth + EXPIRY_TIME < block.timestamp){
      emit OracleRequestTimeout(_requestId, birth, block.timestamp, "timeout after 5 min");
      return true;
    }

    responseInfo memory respA = responseInfo(tx.origin, score,resp,err);

    functionResponse[_requestId].push(respA);
    return true;
  }

  function selectResponse(responseInfo[] memory respArr)private{
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

  function commitResp(bytes32 reqId, responseInfo[] memory respArr)private{
    if (respArr.length == 0) {
      emit OracleRequestTimeout(reqId,0,0, "timeout");
      return;
    }
 
    uint256 vtfValue = uint256(blockhash(block.number-1));
    responseInfo memory ret;
    if(respSelector.length > 0) {
       ret = respArr[respSelector[vtfValue % respSelector.length]];
    }else{
      ret = respArr[vtfValue % respArr.length];
    }
    emit RequestFulfilled(reqId, ret.node,ret.score,ret.resp,ret.err);
  }

  function getReqFromQueen(uint qIndex) private view returns(requestBirth memory reqInfo, bool isDel){
    bytes32 reqId = DoubleEndedQueue.at(reqQueen, qIndex);
    reqInfo = reqMap[reqId];
    if (reqInfo.birth == 0 && reqInfo.msgSender == address(0)){
       isDel = true;
       return (reqInfo, isDel); 
    }
    isDel = false;
    return (reqInfo, isDel);
  }

  function fulfillOracleRequest() external override returns (bool) {

    bool isPopFront;
    delete respSelector;
    
    for (uint reqIndex = 0; reqIndex < DoubleEndedQueue.length(reqQueen); reqIndex++) {

      requestBirth memory reqInfo;
      bool isDel;

      (reqInfo, isDel)= getReqFromQueen(reqIndex);

      if (isDel) {
        continue;
      }

      bool isTimeout = reqInfo.birth + EXPIRY_TIME < block.timestamp;
      responseInfo[] memory respArr =functionResponse[reqInfo.requestId];

      if (isTimeout && respArr.length == 0) {
        commitResp(reqInfo.requestId,respArr);
        delete reqMap[reqInfo.requestId];
        emit OracleRequestTimeout(reqInfo.requestId,0,0, "not found response");

        if (reqIndex == 0) {
          isPopFront = true;
        }

        continue;
      }

      if (respArr.length == 0) {
        continue;
      }

      selectResponse(respArr);
      commitResp(reqInfo.requestId, respArr);
      delete reqMap[reqInfo.requestId];
      if (reqIndex == 0) {
          isPopFront = true;
        }

    }

    if (isPopFront && !DoubleEndedQueue.empty(reqQueen)){
        DoubleEndedQueue.popFront(reqQueen);
    }
    return true;
  }

  function getSelectorResp(uint i) private view returns(uint){
    if (i>respSelector.length){
      return respSelector[0];
    }
      return respSelector[i]; 
  }
  /**
   * @dev Reverts if request ID does not exist
   * @param _requestId The given request ID to check in stored `callbacks`
   */
  modifier isValidRequest(bytes32 _requestId) {

    require(reqMap[_requestId].birth != 0, "Must have a valid requestId");
    _;
  }


  function computeRequestId(
    address nodeAddr,
    address client,
    bytes32 subscriptionId,
    uint256 nonce
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(nodeAddr, client, subscriptionId, nonce));
  }

  function isContract(address token) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(token)
        }
        return size > 0;
    }
}
