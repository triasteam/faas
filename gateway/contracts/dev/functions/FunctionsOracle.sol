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
  event SelectedResponse(bytes32 indexed id,address indexed node, uint score,bytes result, bytes err);
 
  error EmptyRequestData();
  error InconsistentReportData();
  error EmptyPublicKey();
  error EmptyBillingRegistry();
  error UnauthorizedPublicKeyChange();

  struct ResponseInfo {
    bytes32 requestId;
    address funcTxAddress;
    address node;
    uint score;
    bytes resp;
    bytes err;
  }

  

  uint256 constant public EXPIRY_TIME = 5 minutes;
  mapping(bytes32 => mapping(address => bool)) private allowedOracles;
  //  mapping(bytes32 => Callback) private callbacks;//requestId

  //requestId => node address => responseInfo
  mapping(bytes32 => mapping( address => ResponseInfo)) private functionResponse;
  // requestId => resp address queue by time (young -> old) and score (big -> little)
  mapping(bytes32 => DoubleEndedQueue.Bytes32Deque) private sortRespAddr;
  mapping(bytes32 => ResponseInfo) public onlyResp;
  
  DoubleEndedQueue.Bytes32Deque reqQueen; // request birth
  mapping(bytes32 => RequestBirth) reqMap;//requestId => reqInfo

  ResponseInfo[] public respSelector;

  Registry private reg;


  function init() public override {
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
    reqMap[requestId]=RequestBirth(requestId, functionId, block.timestamp, msg.sender, data);
    return requestId;
  }

  function getReq(bytes32 requestId) public override view returns(RequestBirth memory){
    return reqMap[requestId];
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

    ResponseInfo memory respA = ResponseInfo(_requestId,reqMap[_requestId].msgSender,tx.origin, score, resp, err);

    functionResponse[_requestId][tx.origin] = respA;


    if (DoubleEndedQueue.empty(sortRespAddr[_requestId])) {
      DoubleEndedQueue.pushFront(sortRespAddr[_requestId],bytes32(uint256(uint160(tx.origin))));
      return true;
    }

    bytes32 addrBytes = DoubleEndedQueue.front(sortRespAddr[_requestId]);
    ResponseInfo memory oldResp =  functionResponse[_requestId][address(uint160(uint256(addrBytes)))];
    if (oldResp.score <= score){
      DoubleEndedQueue.pushFront(sortRespAddr[_requestId], bytes32(uint256(uint160(tx.origin))));
    }else{
      DoubleEndedQueue.pushBack(sortRespAddr[_requestId], bytes32(uint256(uint160(tx.origin))));
    }

    return true;
  }


  function selectResp(
    bool isTimeout,
    bytes32 requestId
  ) private view returns(ResponseInfo memory tmpResp,bool isWaitNextBlock){

    if (isTimeout && DoubleEndedQueue.empty(sortRespAddr[requestId])) {
      return (tmpResp, isWaitNextBlock);
    }

    if (DoubleEndedQueue.empty( sortRespAddr[requestId])){
      isWaitNextBlock = true;
      return (tmpResp, isWaitNextBlock);
    }

    bytes32 addrBytes;
    if (DoubleEndedQueue.length(  sortRespAddr[requestId]) == 1){
      addrBytes = DoubleEndedQueue.front( sortRespAddr[requestId]);
      tmpResp = functionResponse[requestId][address(uint160(uint256(addrBytes)))];
      return (tmpResp, isWaitNextBlock);
    }

    
    addrBytes = DoubleEndedQueue.front( sortRespAddr[requestId]);
    // max score
    tmpResp = functionResponse[requestId][address(uint160(uint256(addrBytes)))];

    // uint splitIndex = 0;
    // for (uint i = 1; i < DoubleEndedQueue.length(  sortRespAddr[requestId])-1; i++) {
    //     addrBytes = DoubleEndedQueue.at(  sortRespAddr[requestId], i);
    //     ResponseInfo memory oldTmpResp = functionResponse[requestId][address(uint160(uint256(addrBytes)))];
    //     if (tmpResp.score > oldTmpResp.score || oldTmpResp.score==0 ){
    //       break;
    //     }
    //     tmpResp = oldTmpResp;
    //     splitIndex++;
    // }
    // if (splitIndex != 0) {
    //   uint256 vtfValue = uint256(blockhash(block.number-1));
    //   splitIndex = vtfValue % splitIndex + 1;
    // }
 
    // addrBytes = DoubleEndedQueue.at(sortRespAddr[requestId], splitIndex);
    // tmpResp = functionResponse[requestId][address(uint160(uint256(addrBytes)))];
  
    return (tmpResp, isWaitNextBlock);
  }

  function getReqFromQueen(uint qIndex) private view returns(RequestBirth memory reqInfo, bool isDel){
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
    
    for (uint reqIndex = 0; reqIndex < DoubleEndedQueue.length(reqQueen); reqIndex++) {

      RequestBirth memory reqInfo;
      bool isDel;

      (reqInfo, isDel)= getReqFromQueen(reqIndex);
      if (isDel) {
        continue;
      }

      bool isTimeout = reqInfo.birth + EXPIRY_TIME < block.timestamp;

      ResponseInfo memory tmpResp;
      bool isWait;

      (tmpResp, isWait) = selectResp(isTimeout, reqInfo.requestId);

      if (isWait){
        continue;
      }

      if (tmpResp.node == address(0)){
          emit OracleRequestTimeout(reqInfo.requestId, reqInfo.birth, block.timestamp, 
            "no node execute function, timeout");
          // delete functionResponse[reqInfo.requestId];
          // delete sortRespAddr[reqInfo.requestId];
          delete reqMap[reqInfo.requestId];
          return true;
      }

      onlyResp[reqInfo.requestId]= tmpResp;
      emit SelectedResponse(reqInfo.requestId, 
            tmpResp.node, tmpResp.score, tmpResp.resp, tmpResp.err);


      if (reqIndex == 0){
        isPopFront = true;
      }
      delete reqMap[reqInfo.requestId];
    }

    if (isPopFront && !DoubleEndedQueue.empty(reqQueen)){
        DoubleEndedQueue.popFront(reqQueen);
    }
    
    return true;
  }

  function getRespWith(bytes32 reqID) public  returns(ResponseInfo[] memory){
    delete respSelector;


    for (uint i = 0; i< DoubleEndedQueue.length(sortRespAddr[reqID]); i++){
      bytes32 addrBytes = DoubleEndedQueue.at(sortRespAddr[reqID], i);
      respSelector.push(functionResponse[reqID][address(uint160(uint256(addrBytes)))]);
    }
  
      return respSelector; 
  }

  function getOnlyRespWith(bytes32 reqID) public view returns(ResponseInfo memory){
  
      return  onlyResp[reqID]; 
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
