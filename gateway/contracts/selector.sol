// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract Selector {
     

    event vrf(bytes v);
    mapping(string => string) nodeLevel;
    mapping (bytes32 => address) functions;
    bool vrfLock;
    bytes vrfValue;

    function setLevel(string[] memory addrToLevel) public {
     
        require(addrToLevel.length%2==0,"arg is wrong");

        for(uint i = 0; i + 1 < addrToLevel.length;){
            nodeLevel[addrToLevel[i]]=addrToLevel[i+1];
            i=i+2;
        }
    }

    function setFunction(bytes32 node, address owner) public {
        functions[node]=owner;
    }

    function setVRF(bytes memory v) public {
        if (!vrfLock){
            vrfValue=v;
            vrfLock = true;
            emit vrf(v);
        }
    }
}
