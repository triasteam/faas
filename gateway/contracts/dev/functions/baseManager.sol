
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./registry.sol";

interface BaseManager {
    // event ControllerAdded(address indexed controller);
    // event ControllerRemoved(address indexed controller);
    // event NameMigrated(
    //     uint256 indexed id,
    //     address indexed owner,
    //     uint256 expires
    // );
    // event NameRegistered(
    //     uint256 indexed id,
    //     address indexed owner,
    //     uint256 expires
    // );
    event MetaDataUpdated( address indexed managerAddr,address[]  nodeAddrList, bytes funcMeta);
    event NewMangerMember(address indexed memAddr, address indexed managerAddr, bytes funcMeta);

    // Set the resolver for the TLD this registrar manages.
    function registerManager(string memory name) external;
    function IsExistedFunction(string memory functionName)external view returns(bool);
    function getName(address m) external view  returns(bytes32) ;
    function getMembersCounts() external view returns(uint);
 
    function registerNode(
        address owner
    ) external returns (uint256);

    function updateMetaData(string memory functionName,string memory Lang,string memory functionCode, bool doUpdate, string[] memory envVars ) external;
    function getMetaData(string memory functionName) external view returns(bytes memory);
}