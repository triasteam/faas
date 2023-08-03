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

    function setVRF(uint vrf, uint blockNum, string blockHash) public{
        _lastVrfInfo.blockHash=blockHash;
        _lastVrfInfo.blockNum=blockNum;
        _lastVrfInfo.vrf=vrf;
    }
    function getFunctionOwner(bytes32 node, bytes memory vrfValue,  bytes trustInfo, address[] nodes) public view returns(address){

            uint256 num = uint256(bytes32(vrfValue));
            uint256 nodeCounts = nodes.length;
            uint nodeIndex = num % nodeCounts;
            address addr = nodes[nodeIndex];
            emit functionExecutor(addr, vrfValue,  nodes.length, nodeIndex, trustInfo);
            return  nodes[nodeIndex];
    }
}
