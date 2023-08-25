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

    
    mapping(address => bytes32) public memberNames;

    bytes functionMetaData;

    Counters.Counter private membersCounts;

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



    // Set the resolver for the TLD this registrar manages.
    function setManager(address resolver) external override  {}

    function getMembersCounts() public view override returns(uint)  {
        return membersCounts.current();
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
        membersCounts.increment();
        return block.timestamp;
    }



    function updateMetaData(bytes memory funcBytes) external override{
        functionMetaData = funcBytes;
        emit MetaDataUpdated(funcBytes);
        return;
    }
  
}
