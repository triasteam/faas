// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface Registry {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address _owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address _owner);

    // Logged when the manager for a node changes.
    event NewManager(bytes32 indexed node, address manager);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed _owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address _owner,
        address _resolver
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address _owner,
        address _resolver
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address _owner
    ) external returns (bytes32);

    function setManager(bytes32 node, address _resolver) external;

    function setOwner(bytes32 node, address _owner) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function manager(bytes32 node) external view returns (address);


    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(
        address _owner,
        address operator
    ) external view returns (bool);
}
