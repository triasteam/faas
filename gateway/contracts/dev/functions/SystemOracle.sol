// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../interfaces/FunctionsOracleInterface.sol";


contract SystemOracle {
  
    FunctionsOracleInterface private allowedOracles;
  
    function init() public  {
          allowedOracles = FunctionsOracleInterface(address(0x0000000000000000000000000000000000002004));
    }

    function fulfillOracleRequest() external returns (bool) {
        
        return allowedOracles.fulfillOracleRequest();
    }

}