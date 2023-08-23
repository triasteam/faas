// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./baseManager.sol";

contract Selector {
     
     struct LastVRFInfo {
        uint vrf;
        uint blockNum;
        bytes proof;
    }



    struct RequestBirth {
        bytes32 requestId;
        uint blockNumber;
    }

    LastVRFInfo _lastVrfInfo;

    // mapping(uint => bytes32) request_birth; // block number => request id
    mapping(bytes32 => Level[]) pendding_request;// requestID => worker level
    mapping(RequestBirth => address) consumer;// requestID => worker address

    event functionExecutor(address indexed node, bytes indexed vrfValue,  uint nodeCounts, uint nodeIndex, bytes trustInfo);

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


    function updateLevel(bytes32 requestId, uint level){
        pendding_request[requestId]=Level(msg.sender,level);
    }

    function selectorExecutor(){

        block.

    }
}
