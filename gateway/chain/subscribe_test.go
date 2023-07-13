package chain

import (
	"testing"
	"time"
)

func TestParseLog(t *testing.T) {
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
