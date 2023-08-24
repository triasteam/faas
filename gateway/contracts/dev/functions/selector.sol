// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./baseManager.sol";

contract Selector {
     
     struct LastVRFInfo {
        uint vrf;
        uint blockNum;
        bytes proof;
    }

    LastVRFInfo _lastVrfInfo;

    function init() public {}

    function setVRF(uint vrf, bytes memory proof, uint blockNum) public {
        _lastVrfInfo.proof=proof;
        _lastVrfInfo.blockNum=blockNum;
        _lastVrfInfo.vrf=vrf;
    }

     function getProof(uint blockNum) public view returns(bytes memory){
        require(blockNum==_lastVrfInfo.blockNum," not found block num");
        return  _lastVrfInfo.proof;
    }
    
    function getVRF() public view returns(uint){
      return _lastVrfInfo.vrf;
    }
  
}
