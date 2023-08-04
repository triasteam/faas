// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./registry.sol";
import "./selector.sol";
/**
 * The Function registry contract.
 */
contract FunctionRegistry is Registry {
    struct Record {
        address owner;
        address manager;
    }

    // function full name => {node address, _}
    mapping(bytes32 => Record) records;
    // function manager => node address => bool
    mapping(address => mapping(address => bool)) operators;

    mapping(address => bool) public controllers;
    
    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 node) {
        address _owner = records[node].owner;
        require(_owner == msg.sender || controllers[msg.sender] || operators[_owner][msg.sender]);
        _;
    }

    modifier onlyController() {
        require(controllers[msg.sender]);
        _;
    }
    /**
     * @dev Constructs a new ENS registry.
     */
    constructor(Selector _selector)  {
        records[0x0].owner = msg.sender;
        controllers[msg.sender]=true;
        selector = _selector;
    }

    function SetController(address _owner) public {
        controllers[_owner]=true;
    }

    /**
     * @dev Sets the record for a node.
     * @param node The node to update.
     * @param _owner The address of the new owner.
     * @param _manager The address of the manager contract.
     */
    function setRecord(
        bytes32 node,
        address _owner,
        address _manager
    ) external virtual override {
        setOwner(node, _owner);
        _setManager(node, _manager);
    }

    /**
     * @dev Sets the record for a subnode.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     * @param _resolver The address of the manager.
     */
    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address _owner,
        address _resolver
    ) external virtual override {
        bytes32 subnode = setSubnodeOwner(node, label, _owner);
        _setManager(subnode, _resolver);
    }

    /**
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param _owner The address of the new owner.
     */
    function setOwner(
        bytes32 node,
        address _owner
    ) public virtual override authorised(node) {
        _setOwner(node, _owner);
        emit Transfer(node, _owner);
    }

    /**
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     */
    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address _owner
    ) public virtual override authorised(node) returns (bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, _owner);
        emit NewOwner(node, label, _owner);
        return subnode;
    }

    /**
     * @dev Sets the manager address for the specified node.
     * @param node The node to update.
     * @param _manager The address of the manager.
     */
    function setManager(
        bytes32 node,
        address _manager
    ) public virtual override authorised(node) {
        emit NewManager(node, _manager);
        records[node].manager = _manager;
    }


    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s ENS records. Emits the ApprovalForAll event.
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(
        address operator,
        bool approved
    ) external virtual override {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(
        bytes32 node
    ) public view virtual override returns (address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the manager for the specified node.
     * @param node The specified node.
     * @return address of the manager.
     */
    function manager(
        bytes32 node
    ) public view virtual override returns (address) {
        return records[node].manager;
    }



    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(
        bytes32 node
    ) public view virtual override returns (bool) {
        return records[node].owner != address(0x0);
    }

    /**
     * @dev Query if an address is an authorized operator for another address.
     * @param _owner The address that owns the records.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(
        address _owner,
        address operator
    ) external view virtual override returns (bool) {
        return operators[_owner][operator];
    }

    function _setOwner(bytes32 node, address _owner) internal virtual {
        records[node].owner = _owner;
        // selector.setFunction(node, _owner);
    }

    function _setManager(
        bytes32 node,
        address _manager
    ) internal {
        if (_manager != records[node].manager) {
            records[node].manager = _manager;
            // selector.setManager(node, _manager);
            emit NewManager(node, _manager);
        }
    }

    function getSelector() public view returns(address){
        return address(selector);
    }
}
