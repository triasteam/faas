// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./baseManager.sol";

contract Selector {
     
     struct LastVRFInfo {
        uint vrf;
        uint blockNum;
        string blockHash;
    }

    LastVRFInfo _lastVrfInfo;

    mapping(address => bool) generators;

    event functionExecutor(address indexed node, bytes indexed vrfValue,  uint nodeCounts, uint nodeIndex, bytes trustInfo);

    function setVRF(uint vrf, uint blockNum, string memory blockHash) public{
        _lastVrfInfo.blockHash=blockHash;
        _lastVrfInfo.blockNum=blockNum;
        _lastVrfInfo.vrf=vrf;
    }
    
     function getVRF() public view returns(uint){
      return _lastVrfInfo.vrf;
    }
}
