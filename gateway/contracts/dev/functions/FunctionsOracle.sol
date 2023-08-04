// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/FunctionsOracleInterface.sol";

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
  // event OracleResponse(bytes32 indexed requestId);
  // event UserCallbackError(bytes32 indexed requestId, string reason);
  // event UserCallbackRawError(bytes32 indexed requestId, bytes lowLevelData);
  // event InvalidRequestID(bytes32 indexed requestId);

  error EmptyRequestData();
  error InconsistentReportData();
  error EmptyPublicKey();
  error EmptyBillingRegistry();
  error UnauthorizedPublicKeyChange();


  function sendRequest(
    bytes32 subscriptionId,
    bytes calldata data,
    uint32 gasLimit
  ) external override returns (bytes32) {

    if (data.length == 0) {
      revert EmptyRequestData();
    }

    // msg.sender, tx.origin 反了
  
    bytes32 requestId = computeRequestId( tx.origin,msg.sender, subscriptionId,0);

    emit OracleRequest(
      requestId,
      msg.sender,
      tx.origin,
      subscriptionId,
      address(0x0),
      data
    );
    return requestId;
  }

  function computeRequestId(
    address nodeAddr,
    address client,
    bytes32 subscriptionId,
    uint64 nonce
  ) private pure returns (bytes32) {
    return keccak256(abi.encode(nodeAddr, client, subscriptionId, nonce));
  }
  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}
