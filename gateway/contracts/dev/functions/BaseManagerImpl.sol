// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./registry.sol";
import "./baseManager.sol";
import "./Functions.sol";

contract BaseManagerImpl is ERC721, BaseManager{
    using Counters for Counters.Counter;

    // The function registry
    Registry internal reg;
    // The name hash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;

    mapping(address => uint256) public memberNames;

    Functions.FunctionRecord public FunctionMetaData;

    Counters.Counter private membersCounts;
    Counters.Counter private versionRecord;

    constructor(Registry _reg) ERC721("", "") {
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

    /**
     * @dev Gets the owner of the specified token ID. Names become unowned
     *      when their registration expires.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(
        uint256 tokenId
    ) public view override(IERC721, ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    function setRegistry(
        address _reg
    ) public {
        reg = Registry(_reg);
        return;
    }



    // Set the resolver for the TLD this registrar manages.
    function registerManager(string memory functionName) external override  {
        // TODO: verify msg sender
        baseNode = keccak256(bytes(functionName));
        FunctionMetaData.name=functionName;
        reg.setManager(baseNode, address(this));
    }

    function getMembersCounts() public view override returns(uint)  {
        return membersCounts.current();
    }

    function getName(address m) public view override returns(bytes32) {
      return bytes32(memberNames[m]);
    }

    /**
     * @dev Register a name.
     * @param owner The address that should deploy the function.
     */
    function register(
        address owner
    ) public override returns (uint256) {
        membersCounts.increment();
        uint256 id = membersCounts.current();
        memberNames[owner]=id;
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

        _mint(owner,uint256(subNode));

        return block.timestamp;
    }

    function updateMetaData(string memory Lang,string memory functionCode, bool doUpdate,string[] memory envVars ) external override{
        // TODO: verify msg sender
        FunctionMetaData.codeFrom=functionCode;
        FunctionMetaData.doUpdate=doUpdate;
        FunctionMetaData.envVars = envVars;
        FunctionMetaData.language = Lang;
        versionRecord.increment();
        FunctionMetaData.version=versionRecord.current();

        emit MetaDataUpdated( msg.sender,address(this), Functions.encodeFunctionRecord(FunctionMetaData));
        return;
    }

    function getMetaData() external override view returns(bytes memory){

        return Functions.encodeFunctionRecord(FunctionMetaData);
    }
    
    function emitMetaData() external {
        emit MetaDataUpdated( msg.sender,address(this), Functions.encodeFunctionRecord(FunctionMetaData));
    }
    
}
