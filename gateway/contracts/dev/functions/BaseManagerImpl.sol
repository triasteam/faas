// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./registry.sol";
import "./baseManager.sol";
import "./Functions.sol";

contract BaseManagerImpl is BaseManager{
    using Counters for Counters.Counter;

    // The function registry
    Registry internal reg;
    // The name hash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    mapping(address => uint256) public memberNames;
    address[] private memberAddrs;

    Functions.FunctionRecord public FunctionMetaData;

    Counters.Counter private versionRecord;

    constructor(Registry _reg){
        reg = _reg;
    }

    modifier live() {
        // require(reg.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController() {
        // require(controllers[msg.sender]);
        _;
    }

    function setRegistry(
        address _reg
    ) public {
        reg = Registry(_reg);
        return;
    }

     function registerInfo(string memory functionName,address[] memory nodeAddr) external{
        // TODO: verify msg sender
        baseNode = keccak256(bytes(functionName));
        FunctionMetaData.name=functionName;
        reg.setManager(baseNode, address(this));
        for (uint i = 0; i < nodeAddr.length; i++){
            memberAddrs.push(nodeAddr[i]);
            uint256 id = memberAddrs.length;
            memberNames[nodeAddr[i]]=id;
            _register(id, nodeAddr[i], true);
        }
    }

    // Set the resolver for the TLD this registrar manages.
    function registerManager(string memory functionName) external override  {
        // TODO: verify msg sender
        baseNode = keccak256(bytes(functionName));
        FunctionMetaData.name=functionName;
        reg.setManager(baseNode, address(this));
    }

    function getMembersCounts() public view override returns(uint)  {
        return memberAddrs.length;
    }

    function getName(address m) public view override returns(bytes32) {
      return bytes32(memberNames[m]);
    }

    
    function registerNode(
        address owner
    ) public override returns (uint256) {
        memberAddrs.push(owner);
        uint256 id = memberAddrs.length;
        memberNames[owner]=id;
        emit NewMangerMember(owner, address(this), Functions.encodeFunctionRecord(FunctionMetaData));
        return _register(id, owner, true);
    }
   


    function _register(
        uint256 id,
        address owner,
        bool updateRegistry
    ) internal live onlyController returns (uint256) {

        bytes32 subNode;
        if (updateRegistry) {
            subNode = reg.setSubnodeOwner(baseNode, bytes32(id), owner);
        }else{
            subNode = keccak256(abi.encodePacked(baseNode, bytes32(id)));
        }

        return uint256(subNode);
    }

    function updateMetaData(string memory Lang,string memory functionCode, bool doUpdate,string[] memory envVars ) external override{
        // TODO: verify msg sender
        FunctionMetaData.codeFrom=functionCode;
        FunctionMetaData.doUpdate=doUpdate;
        FunctionMetaData.envVars = envVars;
        FunctionMetaData.language = Lang;
        versionRecord.increment();
        FunctionMetaData.version=versionRecord.current();

        emitMetaData();
        return;
    }

    function getMetaData() external override view returns(bytes memory){

        return Functions.encodeFunctionRecord(FunctionMetaData);
    }
    
    function emitMetaData() public {
        emit MetaDataUpdated( memberAddrs,address(this), Functions.encodeFunctionRecord(FunctionMetaData));
    }
    
}
