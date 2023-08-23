// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "./registry.sol";
import "./baseManager.sol";
import "./selector.sol";
import "../interfaces/FunctionsOracleInterface.sol";

/**
 * @title The Coordinator handles oracle service agreements between one or more oracle nodes
 */
contract Coordinator  {

  uint256 constant public EXPIRY_TIME = 5 minutes;

  struct Callback {
    bytes32 sAId;
    uint256 amount;
    address addr;
    bytes4 functionId;
    uint64 cancelExpiration;
    uint8 responseCount;
    mapping(address => uint256) responses;
  }

  struct responseInfo {
    address node;
    uint score;
    bytes resp;
  }

  mapping(bytes32 => mapping(address => bool)) private allowedOracles;
  //  mapping(bytes32 => Callback) private callbacks;//requestId
  mapping(bytes32 => mapping(bytes32 => responseInfo)) private functionResponse;//requestId => function alias => responseInfo
  mapping(bytes32 => uint) private requestBirth; // request birth

  Selector private selector;
  Registry private reg;
  FunctionsOracleInterface internal s_oracle;

  constructor(address oracle,Selector _selector ,Registry _reg) {
    setOracle(oracle);
    reg = _reg;
    selector = _selector;
  }

  /**
   * @notice Called by the node to fulfill requests
   * @dev Response must have a valid callback, and will delete the associated callback storage
   * before calling the external contract.
   * @param _requestId The fulfillment request ID that must match the requester's
   * @param _data The data to return to the consuming contract
   * @return Status if the external call was successful
   */

  function setOracleRequest(
    bytes32 _requestId,
    uint score,
    bytes _data
  ) external isValidRequest(_requestId) returns (bool) {
    Callback memory callback = callbacks[_requestId];

    responseInfo memory resp = responseInfo(msg.sender,score,_data);

    return true;
  }
  function fulfillOracleRequest() external isValidRequest(_requestId) returns (bool) {
    Callback memory callback = callbacks[_requestId];

    responseInfo memory resp = responseInfo(msg.sender,score,_data);

    return true;
  }

  /**
   * @dev Reverts if request ID does not exist
   * @param _requestId The given request ID to check in stored `callbacks`
   */
  modifier isValidRequest(bytes32 _requestId) {
    require(callbacks[_requestId].addr != address(0), "Must have a valid requestId");
//    require(allowedOracles[callbacks[_requestId].sAId][msg.sender], "Oracle not recognized on service agreement");
    address managerAddr = reg.manager(req.functionName);

    require(managerAddr != address(0x0), "not found manager");

    BaseManager m = BaseManager(managerAddr);
    bytes32 name =   m.getName(addr);

    require(name != bytes32(0x0), "selected node unregistered");
    _;
  }


}
