
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./registry.sol";

interface BaseManager is IERC721 {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event NameRegistered(
        uint256 indexed id,
        address indexed owner,
        uint256 expires
    );
    event MetaDataUpdated(bytes funcMeta);

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    function getControllerCounts() external returns(uint);

    // Set the resolver for the TLD this registrar manages.
    function setManager(address resolver) external;

    function setBestMember(address[] memory members)external;
    function getBestMember() external returns(address[] memory);
    function getName(address m) external view  returns(bytes32) ;
    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner
    ) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;

    function updateMetaData(bytes memory func) external;
}