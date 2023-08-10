// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./registry.sol";
import "./baseManager.sol";

contract BaseManagerImpl is ERC721, BaseManager{
    using Counters for Counters.Counter;

    // The funtion registry
    Registry internal reg;
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
        memberNames[0x989777E983d4fCcbA32D857D797FDb75C27571C5]=0x6d255fc3390ee6b41191da315958b7d6a1e5b17904cc7683558f98acc57977b4;
        memberNames[0x57A90337cAcDa7b13be6d4308bfCaf3C1d470e6e]=0x4da432f1ecd4c0ac028ebde3a3f78510a21d54087b161590a63080d33b702b8d;
        memberNames[0xaE1b978424393A1444cff1897bcfeFCc78B61EA1]=0x204558076efb2042ebc9b034aab36d85d672d8ac1fa809288da5b453a4714aae;

        bestMember.push(0x989777E983d4fCcbA32D857D797FDb75C27571C5);
        bestMember.push(0x57A90337cAcDa7b13be6d4308bfCaf3C1d470e6e);
        bestMember.push(0xaE1b978424393A1444cff1897bcfeFCc78B61EA1);
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

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external override  {
        controllers[controller] = true;
        controllerCounts.increment();
        emit ControllerAdded(controller);
    }

    // Revoke controller permission for an address.
    function removeController(address controller) external override  {
        controllers[controller] = false;
        controllerCounts.decrement();
        emit ControllerRemoved(controller);
    }

    // Set the resolver for the TLD this registrar manages.
    function setManager(address resolver) external override  {
        // reg.setManager(baseNode, resolver);
    }

    function setBestMember(address[] memory members) public override  {
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
        bytes32 id,
        address owner
    ) public override returns (uint256) {
        
        return _register(uint256(id), owner, true);
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
       
        memberNames[owner]=bytes32(id);

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
