package chain

import (
	"context"
	"log"

	"github.com/ethereum/go-ethereum"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/ethclient"
)

type ChainSubscribe struct {
	contractAddrs []string
	ethCli        *ethclient.Client
}

func (cs ChainSubscribe) watch() {

	var hexAddr []common.Address
	for _, addr := range cs.contractAddrs {
		hexAddr = append(hexAddr, common.HexToAddress(addr))
	}

	query := ethereum.FilterQuery{
		Addresses: hexAddr,
	}
	logs := make(chan types.Log)
	sub, err := cs.ethCli.SubscribeFilterLogs(context.Background(), query, logs)
	if err != nil {
		log.Fatal("failed to start watching eth", "err", err)
	}

	for {
		select {
		case err = <-sub.Err():
			log.Println("failed to watch eth", "err", err)
		case vLog := <-logs:
			//data, err := cs.selectEvent(vLog)
			//if err != nil {
			//	logger.Error("failed to select event", "err", err)
			//	continue
			//}
			log.Println("watched evnet successfully", "data", vLog)
			//aec.pendingTx <- data

		}
	}
}
