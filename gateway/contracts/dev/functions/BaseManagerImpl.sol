// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./registry.sol";
import "./baseManager.sol";

contract BaseManagerImpl is ERC721, BaseManager, Ownable{
    using Counters for Counters.Counter;

    // The funtion registry
    Registry public reg;
    // The namehash of the TLD this registrar owns (eg, .eth)
    bytes32 public baseNode;
    // A map of addresses that are authorised to register and renew names.
    mapping(address => bool) public controllers;
    
    mapping(address => bytes32) public memberNames;

    address[] bestMember;

    bytes functionMetaData;

    Counters.Counter private controllerCounts;

    /**
     * v2.1.3 version of _isApprovedOrOwner which calls ownerOf(tokenId) and takes grace period into consideration instead of ERC721.ownerOf(tokenId);
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.1.3/contracts/token/ERC721/ERC721.sol#L187
     * @dev Returns whether the given spender can transfer a given token ID
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *    is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(
        address spender,
        uint256 tokenId
    ) internal view override returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    constructor(Registry _reg, bytes32 _baseNode) ERC721("", "") {
        reg = _reg;
        baseNode = _baseNode;
        controllers[msg.sender] = true;
    }

    modifier live() {
        require(reg.owner(baseNode) == address(this));
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
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

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external override onlyOwner {
        controllers[controller] = true;
        controllerCounts.increment();
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override onlyOwner {
        controllers[controller] = false;
        controllerCounts.decrement();
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setManager(address resolver) external override onlyOwner {
        reg.setManager(baseNode, resolver);
    }

    function setBestMember(address[] memory members) external override onlyOwner {
       bestMember = members;
    }

    function getBestMember() public view override returns(address[] memory) {
      return bestMember;
    }

     function getName(address m) public view override returns(bytes32) {
      return memberNames[m];
    }

    /**
     * @dev Register a name.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should deploy the function.
     */
    function register(
        uint256 id,
        address owner
    ) external override returns (uint256) {
        
        return _register(id, owner, true);
    }
   
    /**
     * @dev Register a name, without modifying the registry.
     * @param id The token ID (keccak256 of the label).
     * @param owner The address that should deploy the function.
     */
    function registerOnly(
        uint256 id,
        address owner
    ) external returns (uint256) {
        return _register(id, owner, false);
    }

    function _register(
        uint256 id,
        address owner,
        bool updateRegistry
    ) internal live onlyController returns (uint256) {
       
        _mint(owner, id);
        if (updateRegistry) {
            reg.setSubnodeOwner(baseNode, bytes32(id), owner);
        }
       
        emit NameRegistered(id, owner, block.timestamp);

        return block.timestamp;
    }

    /**
     * @dev Reclaim ownership of a name in registry, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external override live {
        require(_isApprovedOrOwner(msg.sender, id));
        reg.setSubnodeOwner(baseNode, bytes32(id), owner);
    }

    function updateMetaData(bytes memory funcBytes) external override{
        functionMetaData = funcBytes;
        emit MetaDataUpdated(funcBytes);
        return;
    }
  
    
    function getControllerCounts() public view override returns(uint){
         uint num = controllerCounts.current();
         return num;
    }
}
