// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/FunctionsOracleInterface.sol";


contract SystemOracle is FunctionsOracleInterface {
  
    FunctionsOracleInterface private allowedOracles;
  
    function init() public override {
          allowedOracles = FunctionsOracleInterface(address(0x0000000000000000000000000000000000002004));
    }

    function sendRequest(bytes32 ,bytes memory) external  override pure returns (bytes32) {
        bytes32 a;
        return a;
    }

    function fulfillRequestByNode(bytes32 ,uint ,bytes calldata ,bytes calldata) public override pure returns (bool) {
        return true;
    }


    function fulfillOracleRequest() external override returns (bool) {
        
        return allowedOracles.fulfillOracleRequest();
    }

}