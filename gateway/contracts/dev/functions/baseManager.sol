
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

    // Set the resolver for the TLD this registrar manages.
    function setManager(address resolver) external;

    function getName(address m) external view  returns(bytes32) ;
    function getMembersCounts() external view returns(uint);
    /**
     * @dev Register a name.
     */
    function register(
        bytes32 id,
        address owner
    ) external returns (uint256);

    function updateMetaData(bytes memory func) external;
}