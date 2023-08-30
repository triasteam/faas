package metrics

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/url"
	"time"

	"github.com/pkg/errors"

	"github.com/hashicorp/go-retryablehttp"
	types "github.com/openfaas/faas-provider/types"
	"github.com/openfaas/faas/gateway/logger"
)

const (
	defaultSenderBufferSize = 10

	envFaasVerifierProvider = "faas_verifier_provider"
	envFaasNodeAddress      = "faas_node_address"
)

type FunctionReporter interface {
	SendFunctions(functions []types.FunctionStatus)
}

type VerifierReporter struct {
	vc     *VerifierConfig
	client *retryablehttp.Client

	functionChan chan []string
}

func NewVerifierReporter() (*VerifierReporter, error) {
	envReader := types.OsEnv{}
	vc, err := loadConfig(envReader)
	if err != nil {
		return nil, errors.WithMessage(err, "verifier config exception")
	}
	vr := &VerifierReporter{
		vc:           vc,
		functionChan: make(chan []string, vc.SenderBufferSize),
	}

	go vr.send()
	return vr, nil
}

type VerifierConfig struct {
	ReporterUrl      *url.URL
	SenderBufferSize int
	Address          string
}

func loadConfig(envReader types.HasEnv) (*VerifierConfig, error) {
	var err error
	vc := VerifierConfig{
		SenderBufferSize: defaultSenderBufferSize,
	}

	if len(envReader.Getenv(envFaasVerifierProvider)) > 0 {
		vc.ReporterUrl, err = url.Parse(envReader.Getenv(envFaasVerifierProvider))
		if err != nil {
			return nil, fmt.Errorf("if faas_verifier_provider is provided, then it should be a valid URL, error: %s", err)
		}
	}
	vc.Address = envReader.Getenv(envFaasNodeAddress)
	if len(vc.Address) == 0 {
		return nil, fmt.Errorf("not found node Address from env")
	}
	logger.Info("load verifier sender config", "value", vc)
	return &vc, nil
}

func (vr VerifierReporter) send() {

	type FunctionInfo struct {
		Address string   `json:"address"`
		Funcs   []string `json:"funcs"`
	}

	functionsSender := func(fi FunctionInfo) {
		method := "POST"
		client := retryablehttp.NewClient()
		client.RetryMax = 5

		marshal, err := json.Marshal(fi)
		if err != nil {
			logger.Error("failed to marshal verifier request", "functionInfo", fi, "err", err)
			return
		}
		bodyReader := bytes.NewReader(marshal)

		req, err := retryablehttp.NewRequest(method, vr.vc.ReporterUrl.String(), bodyReader)

		if err != nil {
			logger.Error("failed to create verifier request", "err", err)
			return
		}
		req.Header.Add("Content-Type", "application/json")

		res, err := client.Do(req)
		if err != nil {
			logger.Error("failed to send verifier request", "err", err)
			return
		}
		defer res.Body.Close()

		body, err := io.ReadAll(res.Body)
		if err != nil {
			logger.Error("failed to read verifier respond body", "err", err)
			return
		}
		logger.Info("read verifier respond body", "body", string(body))
	}

	initialDelay := 200
	retries := 0

	for {
		select {
		case functionsInfo := <-vr.functionChan:
			functionsSender(FunctionInfo{vr.vc.Address, functionsInfo})
			retries = 0
		case <-time.After(time.Duration(2^retries*initialDelay) * time.Millisecond):
			retries += 1
		}
	}

}

func (vr VerifierReporter) SendFunctions(functionStatus []types.FunctionStatus) {
	logger.Info("send functions info to verifier")
	defer func() {
		if err := recover(); err != nil {
			logger.Error("panic", "err", err)
		}
	}()
	var functions []string

	for _, f := range functionStatus {
		functions = append(functions, f.Name)
	}

	if len(vr.functionChan) == defaultSenderBufferSize {
		<-vr.functionChan
		logger.Info("function reporter buffer is full, drop the oldest", "len", len(vr.functionChan))
	}
	vr.functionChan <- functions

}
