
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

    // Set the resolver for the TLD this registrar manages.
    function setManager(address resolver) external;


    /**
     * @dev Register a name.
     */
    function register(
        uint256 id,
        address owner,
        uint256 duration
    ) external returns (uint256);

    /**
     * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
     */
    function reclaim(uint256 id, address owner) external;

    function updateMetaData(bytes memory func) external;
}


// interface BaseManager is  Ownable {
//     uint constant public GRACE_PERIOD = 90 days;

//     event ControllerAdded(address indexed controller);
//     event ControllerRemoved(address indexed controller);
//     event NameMigrated(uint256 indexed id, address indexed owner, uint expires);
//     event NameRegistered(uint256 indexed id, address indexed owner, uint expires);
//     event NameRenewed(uint256 indexed id, uint expires);
//     event MetaDataUpdated(bytes funcMeta);
//     // The function registry
//     Registry public reg;

//     // The namehash of the TLD this registrar owns (eg, .eth)
//     bytes32 public baseNode;

//     // A map of addresses that are authorised to register and renew names.
//     mapping(address=>bool) public controllers;

//     // Authorises a controller, who can register and renew domains.
//     function addController(address controller) external;

//     // Revoke controller permission for an address.
//     function removeController(address controller) external;

//     // Set the resolver for the TLD this registrar manages.
//     function setManager(address resolver) external;

//     // Returns true iff the specified name is available for registration.
//     function available(uint256 id) public view returns(bool);

//     /**
//      * @dev Register a name.
//      */
//     function register(uint256 id, address owner, uint duration) external returns(uint);

//     /**
//      * @dev Reclaim ownership of a name in ENS, if you own it in the registrar.
//      */
//     function reclaim(uint256 id, address owner) external;

//     function updateMetaData(bytes memory func) external;
// }
