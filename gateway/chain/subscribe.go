package chain

import (
	"context"
	"encoding/hex"
	"sync"
	"time"

	"github.com/openfaas/faas/gateway/chain/cbor"

	"github.com/avast/retry-go/v4"
	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
	"github.com/openfaas/faas/gateway/chain/actor"
	"github.com/openfaas/faas/gateway/chain/logger"
	"github.com/pkg/errors"
)

type Subscriber struct {
	functionClientAddr string
	functionOracleAddr string
	ethAddr            string
	ethCli             *ethclient.Client
	functionClient     *actor.FunctionClient
	oracleClient       *actor.FunctionOracle

	renewChan   chan struct{}
	dailEthDone chan struct{}
	locker      sync.RWMutex
}

func NewSubscriber(functionClientAddr, functionOracleAddr, nodeAddr string) *Subscriber {

	return &Subscriber{
		functionClientAddr: functionClientAddr,
		functionOracleAddr: functionOracleAddr,
		ethAddr:            nodeAddr,
		renewChan:          make(chan struct{}),
		dailEthDone:        make(chan struct{}),
		locker:             sync.RWMutex{},
	}
}

func (cs *Subscriber) Clean() {
	close(cs.renewChan)
	close(cs.dailEthDone)
	cs.ethCli.Close()
}

func (cs *Subscriber) resetEthCli(cli *ethclient.Client) {
	cs.locker.Lock()
	defer cs.locker.Unlock()
	cs.ethCli = cli
	funcCli, err := actor.NewFunctionClient(common.HexToAddress(cs.functionClientAddr), cs.ethCli)
	if err != nil {
		logger.Error("failed to new FunctionClient", "err", err)
	}
	oracleCli, err := actor.NewFunctionOracle(common.HexToAddress(cs.functionOracleAddr), cs.ethCli)
	if err != nil {
		logger.Error("failed to new FunctionOracle", "err", err)
	}
	cs.oracleClient = oracleCli
	cs.functionClient = funcCli
}

func (cs *Subscriber) retryDailEth(addr string) {
	start := time.Now()
	err := retry.Do(
		func() error {

			ethCli, err := ethclient.Dial(addr)
			if err != nil {
				logger.Error("failed to connect to ", "node addr", cs.ethAddr)
				return err
			}
			cs.resetEthCli(ethCli)
			return nil
		},
		retry.Attempts(0),
		retry.Delay(time.Second),
		retry.MaxDelay(2*time.Second),
	)
	dur := time.Since(start)
	if err != nil {
		logger.Error("retry exception during watching", "err", err)
	}
	logger.Info("re-dail eth cost time", "dur", dur.String())
}

func (cs *Subscriber) ConnectLoop() {
	go func() {
		for {
			select {
			case _, ok := <-cs.renewChan:
				if !ok {
					logger.Error("resubscribe channel is closed")
					panic("resubscribe channel is closed")
				}
				cs.retryDailEth(cs.ethAddr)
				cs.dailEthDone <- struct{}{}

			}
		}
	}()
}

func (cs *Subscriber) watch() {

	query := ethereum.FilterQuery{
		Addresses: []common.Address{common.HexToAddress(cs.functionOracleAddr), common.HexToAddress(cs.functionOracleAddr)},
	}
	logs := make(chan types.Log)
	var (
		sub       ethereum.Subscription
		err       error
		isRenewed bool
	)

	timer := time.NewTicker(time.Second)
	defer timer.Stop()
	for {
		for !isRenewed {
			logger.Info("############# not found chain log event subscriber, resubscribe")
			cs.renewChan <- struct{}{}
			select {
			case <-cs.dailEthDone:
				err = retry.Do(
					func() error {
						logger.Info("start subscribe")
						sub, err = cs.ethCli.SubscribeFilterLogs(context.Background(), query, logs)
						if err != nil {
							logger.Error("failed to finish to subscribe eth", "err", err)
							return err
						}
						logger.Info("finish to subscribe")
						isRenewed = true
						return nil
					},
					retry.Attempts(5),
					retry.Delay(500*time.Millisecond),
					retry.MaxDelay(time.Second),
				)
				if err != nil {
					logger.Error("retry exception during watching", "err", err)
				} else {
					logger.Info("############# finish to resubscribe")
				}
			}
		}

		select {
		case err = <-sub.Err():
			logger.Error("failed to watch eth", "err", err)
			sub.Unsubscribe()
			sub = nil
			isRenewed = false
		case vLog := <-logs:
			data, err := cs.selectEvent(vLog)
			if err != nil {
				logger.Error(err.Error())
				continue
			}
			logger.Info("watched event successfully", "data", data)
		}
	}

}

func (cs *Subscriber) selectEvent(vLog types.Log) (interface{}, error) {
	var (
		data interface{}
	)

	switch vLog.Topics[0].Hex() {
	case RequestFulfilledSignature:
		resp, err := cs.functionClient.ParseRequestFulfilled(vLog)
		if err != nil {
			return nil, err
		}
		logger.Info("parse function response", "resp", string(resp.Result))
		data = resp
	case RequestSentSignature:
		sent, err := cs.functionClient.ParseRequestSent(vLog)
		if err != nil {
			return nil, err
		}
		logger.Info("parse sent function request", "resp", sent.Id)
		data = sent
	case OracleRequestSignature:
		sent, err := cs.oracleClient.ParseOracleRequest(vLog)
		if err != nil {
			return nil, err
		}
		logger.Info("receive request event",
			"requestId", sent.RequestId,
			"requestContract", sent.RequestingContract,
			"requestInitiator", sent.RequestInitiator)

		logger.Debug("request raw data", "log data", string(sent.Data), "hex req data", hex.EncodeToString(sent.Data))

		data = sent
		reqRawDataMap, err := cbor.ParseDietCBOR(sent.Data)
		if err != nil {
			logger.Error("failed to decode contract request", "err", err)
			return nil, err
		}
		logger.Info("decode requested data", "raw ", reqRawDataMap)
	default:
		return nil, errors.Errorf("not support event, topic:%s", vLog.Topics[0].Hex())
	}
	return data, nil
}

type CodeLanguage uint

const (
	NotSupportedLang CodeLanguage = iota
	Golang
)

type Request struct {
	//Location     codeLocation
	//Location     secretsLocation
	language CodeLanguage
	source   string // Source code for Location.Inline or url for Location.Remote
	secrets  []byte // Encrypted secrets blob for Location.Inline or url for Location.Remote
	args     []string
}
