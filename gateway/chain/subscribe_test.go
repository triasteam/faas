package chain

import (
	"context"
	"encoding/hex"
	"fmt"
	"testing"
	"time"

	"github.com/openfaas/faas/gateway/chain/logger"

	"github.com/ethereum/go-ethereum/accounts/abi/bind"
	"github.com/openfaas/faas/gateway/chain/actor"
)

func TestParseLog(t *testing.T) {
	t.Skip()
	ChainAddr := "ws://127.0.0.1:9546"
	//ethCli, err := ethclient.Dial(ChainAddr)
	//if err != nil {
	//	t.Error(err.Error())
	//	return
	//}

	//defer ethCli.Close()
	functionClientAddr, functionOracleAddr := "0xe98a2cBE781B4275aFd985E895E92Aea48B235C7", "0x4B9f0303352a80550455b8323bc9A3D9690ccbDF"

	sub := NewSubscriber(functionClientAddr, functionOracleAddr, ChainAddr)
	defer sub.Clean()
	sub.ConnectLoop()
	go sub.watch()

	time.Sleep(time.Second * 6000)
}

func TestSubscriber_Send(t *testing.T) {
	//t.Skip()
	ChainAddr := "ws://127.0.0.1:9546"

	functionClientAddr, functionOracleAddr := "0xe98a2cBE781B4275aFd985E895E92Aea48B235C7", "0x4B9f0303352a80550455b8323bc9A3D9690ccbDF"

	sub := NewSubscriber(functionClientAddr, functionOracleAddr, ChainAddr)
	sink := make(chan *actor.FunctionClientRequestFulfilled)
	defer close(sink)
	time.Sleep(time.Second * 2)
	sent, err := sub.functionClient.WatchRequestFulfilled(&bind.WatchOpts{Context: context.Background()}, sink, nil)
	if err != nil {
		return
	}
	defer sent.Unsubscribe()
	data := &actor.FunctionClientRequestFulfilled{}
	select {
	case data = <-sink:
	case err = <-sent.Err():
		t.Error(err.Error())
		return
	}
	logger.Info("receive tx ", "tx hash", data.Raw.TxHash.String(), "reqId", hex.EncodeToString(data.Id[:]))
}

func TestNewSubscriber(t *testing.T) {
	a, b := 1, 2
	testSet := []*int{&a, &b}
	testSetPoint := &testSet
	*testSetPoint = (*testSetPoint)[1:]

	fmt.Println(len(*testSetPoint), *testSetPoint)
	*testSetPoint = (*testSetPoint)[1:]
	fmt.Println(len(*testSetPoint), *testSetPoint)
}
