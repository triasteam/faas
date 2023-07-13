// Code generated - DO NOT EDIT.
// This file is a generated binding and any manual changes will be lost.

package actor

import (
	"errors"
	"math/big"
	"strings"

	ethereum "github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/accounts/abi"
	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/event"
)

// Reference imports to suppress errors if they are not otherwise used.
var (
	_ = errors.New
	_ = big.NewInt
	_ = strings.NewReader
	_ = ethereum.NotFound
	_ = bind.Bind
	_ = common.Big1
	_ = types.BloomLookup
	_ = event.NewSubscription
	_ = abi.ConvertType
)

// FunctionOracleMetaData contains all meta data concerning the FunctionOracle contract.
var FunctionOracleMetaData = &bind.MetaData{
	ABI: "[{\"inputs\":[],\"name\":\"EmptyBillingRegistry\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"EmptyPublicKey\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"EmptyRequestData\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"InconsistentReportData\",\"type\":\"error\"},{\"inputs\":[],\"name\":\"UnauthorizedPublicKeyChange\",\"type\":\"error\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":true,\"internalType\":\"bytes32\",\"name\":\"requestId\",\"type\":\"bytes32\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"requestingContract\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"requestInitiator\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"uint64\",\"name\":\"subscriptionId\",\"type\":\"uint64\"},{\"indexed\":false,\"internalType\":\"address\",\"name\":\"subscriptionOwner\",\"type\":\"address\"},{\"indexed\":false,\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"}],\"name\":\"OracleRequest\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"subscriptionId\",\"type\":\"uint64\"},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\"},{\"internalType\":\"uint32\",\"name\":\"gasLimit\",\"type\":\"uint32\"}],\"name\":\"sendRequest\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\"}],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}]",
}

// FunctionOracleABI is the input ABI used to generate the binding from.
// Deprecated: Use FunctionOracleMetaData.ABI instead.
var FunctionOracleABI = FunctionOracleMetaData.ABI

// FunctionOracle is an auto generated Go binding around an Ethereum contract.
type FunctionOracle struct {
	FunctionOracleCaller     // Read-only binding to the contract
	FunctionOracleTransactor // Write-only binding to the contract
	FunctionOracleFilterer   // Log filterer for contract events
}

// FunctionOracleCaller is an auto generated read-only Go binding around an Ethereum contract.
type FunctionOracleCaller struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FunctionOracleTransactor is an auto generated write-only Go binding around an Ethereum contract.
type FunctionOracleTransactor struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FunctionOracleFilterer is an auto generated log filtering Go binding around an Ethereum contract events.
type FunctionOracleFilterer struct {
	contract *bind.BoundContract // Generic contract wrapper for the low level calls
}

// FunctionOracleSession is an auto generated Go binding around an Ethereum contract,
// with pre-set call and transact options.
type FunctionOracleSession struct {
	Contract     *FunctionOracle   // Generic contract binding to set the session for
	CallOpts     bind.CallOpts     // Call options to use throughout this session
	TransactOpts bind.TransactOpts // Transaction auth options to use throughout this session
}

// FunctionOracleCallerSession is an auto generated read-only Go binding around an Ethereum contract,
// with pre-set call options.
type FunctionOracleCallerSession struct {
	Contract *FunctionOracleCaller // Generic contract caller binding to set the session for
	CallOpts bind.CallOpts         // Call options to use throughout this session
}

// FunctionOracleTransactorSession is an auto generated write-only Go binding around an Ethereum contract,
// with pre-set transact options.
type FunctionOracleTransactorSession struct {
	Contract     *FunctionOracleTransactor // Generic contract transactor binding to set the session for
	TransactOpts bind.TransactOpts         // Transaction auth options to use throughout this session
}

// FunctionOracleRaw is an auto generated low-level Go binding around an Ethereum contract.
type FunctionOracleRaw struct {
	Contract *FunctionOracle // Generic contract binding to access the raw methods on
}

// FunctionOracleCallerRaw is an auto generated low-level read-only Go binding around an Ethereum contract.
type FunctionOracleCallerRaw struct {
	Contract *FunctionOracleCaller // Generic read-only contract binding to access the raw methods on
}

// FunctionOracleTransactorRaw is an auto generated low-level write-only Go binding around an Ethereum contract.
type FunctionOracleTransactorRaw struct {
	Contract *FunctionOracleTransactor // Generic write-only contract binding to access the raw methods on
}

// NewFunctionOracle creates a new instance of FunctionOracle, bound to a specific deployed contract.
func NewFunctionOracle(address common.Address, backend bind.ContractBackend) (*FunctionOracle, error) {
	contract, err := bindFunctionOracle(address, backend, backend, backend)
	if err != nil {
		return nil, err
	}
	return &FunctionOracle{FunctionOracleCaller: FunctionOracleCaller{contract: contract}, FunctionOracleTransactor: FunctionOracleTransactor{contract: contract}, FunctionOracleFilterer: FunctionOracleFilterer{contract: contract}}, nil
}

// NewFunctionOracleCaller creates a new read-only instance of FunctionOracle, bound to a specific deployed contract.
func NewFunctionOracleCaller(address common.Address, caller bind.ContractCaller) (*FunctionOracleCaller, error) {
	contract, err := bindFunctionOracle(address, caller, nil, nil)
	if err != nil {
		return nil, err
	}
	return &FunctionOracleCaller{contract: contract}, nil
}

// NewFunctionOracleTransactor creates a new write-only instance of FunctionOracle, bound to a specific deployed contract.
func NewFunctionOracleTransactor(address common.Address, transactor bind.ContractTransactor) (*FunctionOracleTransactor, error) {
	contract, err := bindFunctionOracle(address, nil, transactor, nil)
	if err != nil {
		return nil, err
	}
	return &FunctionOracleTransactor{contract: contract}, nil
}

// NewFunctionOracleFilterer creates a new log filterer instance of FunctionOracle, bound to a specific deployed contract.
func NewFunctionOracleFilterer(address common.Address, filterer bind.ContractFilterer) (*FunctionOracleFilterer, error) {
	contract, err := bindFunctionOracle(address, nil, nil, filterer)
	if err != nil {
		return nil, err
	}
	return &FunctionOracleFilterer{contract: contract}, nil
}

// bindFunctionOracle binds a generic wrapper to an already deployed contract.
func bindFunctionOracle(address common.Address, caller bind.ContractCaller, transactor bind.ContractTransactor, filterer bind.ContractFilterer) (*bind.BoundContract, error) {
	parsed, err := FunctionOracleMetaData.GetAbi()
	if err != nil {
		return nil, err
	}
	return bind.NewBoundContract(address, *parsed, caller, transactor, filterer), nil
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FunctionOracle *FunctionOracleRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FunctionOracle.Contract.FunctionOracleCaller.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FunctionOracle *FunctionOracleRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FunctionOracle.Contract.FunctionOracleTransactor.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FunctionOracle *FunctionOracleRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FunctionOracle.Contract.FunctionOracleTransactor.contract.Transact(opts, method, params...)
}

// Call invokes the (constant) contract method with params as input values and
// sets the output to result. The result type might be a single field for simple
// returns, a slice of interfaces for anonymous returns and a struct for named
// returns.
func (_FunctionOracle *FunctionOracleCallerRaw) Call(opts *bind.CallOpts, result *[]interface{}, method string, params ...interface{}) error {
	return _FunctionOracle.Contract.contract.Call(opts, result, method, params...)
}

// Transfer initiates a plain transaction to move funds to the contract, calling
// its default method if one is available.
func (_FunctionOracle *FunctionOracleTransactorRaw) Transfer(opts *bind.TransactOpts) (*types.Transaction, error) {
	return _FunctionOracle.Contract.contract.Transfer(opts)
}

// Transact invokes the (paid) contract method with params as input values.
func (_FunctionOracle *FunctionOracleTransactorRaw) Transact(opts *bind.TransactOpts, method string, params ...interface{}) (*types.Transaction, error) {
	return _FunctionOracle.Contract.contract.Transact(opts, method, params...)
}

// SendRequest is a paid mutator transaction binding the contract method 0x28242b04.
//
// Solidity: function sendRequest(uint64 subscriptionId, bytes data, uint32 gasLimit) returns(bytes32)
func (_FunctionOracle *FunctionOracleTransactor) SendRequest(opts *bind.TransactOpts, subscriptionId uint64, data []byte, gasLimit uint32) (*types.Transaction, error) {
	return _FunctionOracle.contract.Transact(opts, "sendRequest", subscriptionId, data, gasLimit)
}

// SendRequest is a paid mutator transaction binding the contract method 0x28242b04.
//
// Solidity: function sendRequest(uint64 subscriptionId, bytes data, uint32 gasLimit) returns(bytes32)
func (_FunctionOracle *FunctionOracleSession) SendRequest(subscriptionId uint64, data []byte, gasLimit uint32) (*types.Transaction, error) {
	return _FunctionOracle.Contract.SendRequest(&_FunctionOracle.TransactOpts, subscriptionId, data, gasLimit)
}

// SendRequest is a paid mutator transaction binding the contract method 0x28242b04.
//
// Solidity: function sendRequest(uint64 subscriptionId, bytes data, uint32 gasLimit) returns(bytes32)
func (_FunctionOracle *FunctionOracleTransactorSession) SendRequest(subscriptionId uint64, data []byte, gasLimit uint32) (*types.Transaction, error) {
	return _FunctionOracle.Contract.SendRequest(&_FunctionOracle.TransactOpts, subscriptionId, data, gasLimit)
}

// FunctionOracleOracleRequestIterator is returned from FilterOracleRequest and is used to iterate over the raw logs and unpacked data for OracleRequest events raised by the FunctionOracle contract.
type FunctionOracleOracleRequestIterator struct {
	Event *FunctionOracleOracleRequest // Event containing the contract specifics and raw log

	contract *bind.BoundContract // Generic contract to use for unpacking event data
	event    string              // Event name to use for unpacking event data

	logs chan types.Log        // Log channel receiving the found contract events
	sub  ethereum.Subscription // Subscription for errors, completion and termination
	done bool                  // Whether the subscription completed delivering logs
	fail error                 // Occurred error to stop iteration
}

// Next advances the iterator to the subsequent event, returning whether there
// are any more events found. In case of a retrieval or parsing error, false is
// returned and Error() can be queried for the exact failure.
func (it *FunctionOracleOracleRequestIterator) Next() bool {
	// If the iterator failed, stop iterating
	if it.fail != nil {
		return false
	}
	// If the iterator completed, deliver directly whatever's available
	if it.done {
		select {
		case log := <-it.logs:
			it.Event = new(FunctionOracleOracleRequest)
			if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
				it.fail = err
				return false
			}
			it.Event.Raw = log
			return true

		default:
			return false
		}
	}
	// Iterator still in progress, wait for either a data or an error event
	select {
	case log := <-it.logs:
		it.Event = new(FunctionOracleOracleRequest)
		if err := it.contract.UnpackLog(it.Event, it.event, log); err != nil {
			it.fail = err
			return false
		}
		it.Event.Raw = log
		return true

	case err := <-it.sub.Err():
		it.done = true
		it.fail = err
		return it.Next()
	}
}

// Error returns any retrieval or parsing error occurred during filtering.
func (it *FunctionOracleOracleRequestIterator) Error() error {
	return it.fail
}

// Close terminates the iteration process, releasing any pending underlying
// resources.
func (it *FunctionOracleOracleRequestIterator) Close() error {
	it.sub.Unsubscribe()
	return nil
}

// FunctionOracleOracleRequest represents a OracleRequest event raised by the FunctionOracle contract.
type FunctionOracleOracleRequest struct {
	RequestId          [32]byte
	RequestingContract common.Address
	RequestInitiator   common.Address
	SubscriptionId     uint64
	SubscriptionOwner  common.Address
	Data               []byte
	Raw                types.Log // Blockchain specific contextual infos
}

// FilterOracleRequest is a free log retrieval operation binding the contract event 0xa1ec73989d79578cd6f67d4f593ac3e0a4d1020e5c0164db52108d7ff785406c.
//
// Solidity: event OracleRequest(bytes32 indexed requestId, address requestingContract, address requestInitiator, uint64 subscriptionId, address subscriptionOwner, bytes data)
func (_FunctionOracle *FunctionOracleFilterer) FilterOracleRequest(opts *bind.FilterOpts, requestId [][32]byte) (*FunctionOracleOracleRequestIterator, error) {

	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _FunctionOracle.contract.FilterLogs(opts, "OracleRequest", requestIdRule)
	if err != nil {
		return nil, err
	}
	return &FunctionOracleOracleRequestIterator{contract: _FunctionOracle.contract, event: "OracleRequest", logs: logs, sub: sub}, nil
}

// WatchOracleRequest is a free log subscription operation binding the contract event 0xa1ec73989d79578cd6f67d4f593ac3e0a4d1020e5c0164db52108d7ff785406c.
//
// Solidity: event OracleRequest(bytes32 indexed requestId, address requestingContract, address requestInitiator, uint64 subscriptionId, address subscriptionOwner, bytes data)
func (_FunctionOracle *FunctionOracleFilterer) WatchOracleRequest(opts *bind.WatchOpts, sink chan<- *FunctionOracleOracleRequest, requestId [][32]byte) (event.Subscription, error) {

	var requestIdRule []interface{}
	for _, requestIdItem := range requestId {
		requestIdRule = append(requestIdRule, requestIdItem)
	}

	logs, sub, err := _FunctionOracle.contract.WatchLogs(opts, "OracleRequest", requestIdRule)
	if err != nil {
		return nil, err
	}
	return event.NewSubscription(func(quit <-chan struct{}) error {
		defer sub.Unsubscribe()
		for {
			select {
			case log := <-logs:
				// New log arrived, parse the event and forward to the user
				event := new(FunctionOracleOracleRequest)
				if err := _FunctionOracle.contract.UnpackLog(event, "OracleRequest", log); err != nil {
					return err
				}
				event.Raw = log

				select {
				case sink <- event:
				case err := <-sub.Err():
					return err
				case <-quit:
					return nil
				}
			case err := <-sub.Err():
				return err
			case <-quit:
				return nil
			}
		}
	}), nil
}

// ParseOracleRequest is a log parse operation binding the contract event 0xa1ec73989d79578cd6f67d4f593ac3e0a4d1020e5c0164db52108d7ff785406c.
//
// Solidity: event OracleRequest(bytes32 indexed requestId, address requestingContract, address requestInitiator, uint64 subscriptionId, address subscriptionOwner, bytes data)
func (_FunctionOracle *FunctionOracleFilterer) ParseOracleRequest(log types.Log) (*FunctionOracleOracleRequest, error) {
	event := new(FunctionOracleOracleRequest)
	if err := _FunctionOracle.contract.UnpackLog(event, "OracleRequest", log); err != nil {
		return nil, err
	}
	event.Raw = log
	return event, nil
}
