package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/openfaas/faas/gateway/chain"

	"github.com/openfaas/faas/gateway/types"

	"github.com/openfaas/faas/gateway/chain/logger"
	"github.com/openfaas/faas/gateway/pkg/middleware"
)

func buildUpstreamRequestFromChain(r *http.Request, baseURL string, requestURL string) *http.Request {
	url := baseURL + requestURL

	if len(r.URL.RawQuery) > 0 {
		url = fmt.Sprintf("%s?%s", url, r.URL.RawQuery)
	}
	logger.Info("build upstream request from chain", "uid", r.Header.Get(CallID), "url", url, "method", r.Method)
	logger.Info("build upstream request from chain", "uid", r.Header.Get(CallID), "header", r.Header)
	upstreamReq, _ := http.NewRequest(r.Method, url, nil)

	copyHeaders(upstreamReq.Header, &r.Header)
	deleteHeaders(&upstreamReq.Header, &hopHeaders)

	if len(r.Host) > 0 && upstreamReq.Header.Get("X-Forwarded-Host") == "" {
		upstreamReq.Header["X-Forwarded-Host"] = []string{r.Host}
	}

	if upstreamReq.Header.Get("X-Forwarded-For") == "" {
		upstreamReq.Header["X-Forwarded-For"] = []string{r.RemoteAddr}
	}

	if r.Body != nil {
		upstreamReq.Body = r.Body
	}

	return upstreamReq
}

func forwardRequestFromChain(
	r *http.Request,
	proxyClient *http.Client,
	baseURL string,
	requestURL string,
	timeout time.Duration,
	writeRequestURI bool,
	serviceAuthInjector middleware.AuthInjector) *chain.FulFilledRequest {

	logger.Info("forward request", "uid", r.Header.Get(CallID), "baseURL", baseURL, "requestURL", requestURL)

	upstreamReq := buildUpstreamRequestFromChain(r, baseURL, requestURL)
	if upstreamReq.Body != nil {
		defer upstreamReq.Body.Close()
	}

	if serviceAuthInjector != nil {
		serviceAuthInjector.Inject(upstreamReq)
	}

	if writeRequestURI {
		logger.Info("forwardRequest", "host", upstreamReq.Host, "url", upstreamReq.URL.String())
	}

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	// 合约-> bsc -> gateway.chain -> chainHandler -> function -> chainHandler -> gateway.chain -> resp
	// ui-> gateway.proxyHandler -> function -> gateway -> resp
	ffReq := &chain.FulFilledRequest{
		RequestId: r.Header.Get("requestId"),
	}
	res, resErr := proxyClient.Do(upstreamReq.WithContext(ctx))
	if resErr != nil {
		//badStatus := http.StatusBadGateway
		ffReq.Err = []byte(fmt.Sprintf("code: %d, err: %v ", http.StatusBadGateway, resErr))
		return ffReq
	}

	if res.Body != nil {
		defer res.Body.Close()
	}
	//TODO: process function result
	all, err := io.ReadAll(res.Body)
	if err != nil {
		ffReq.Err = []byte(fmt.Sprintf("code: %d,status: %s, err: %v ", res.StatusCode, res.Status, err.Error()))
		return ffReq
	}

	ffReq.Resp = all
	logger.Info("get result from function", "res", string(all))
	return ffReq
}

type ChainHandler struct {
	proxy                *types.HTTPClientReverseProxy
	serviceAuthInjector  middleware.AuthInjector
	baseURLResolver      middleware.BaseURLResolver
	publisher            chain.Publish
	FunctionsProviderURL string
}

func NewChainHandler(
	proxy *types.HTTPClientReverseProxy,
	baseURLResolver middleware.BaseURLResolver,
	serviceAuthInjector middleware.AuthInjector,
	publisher chain.Publish,
	FunctionsProviderURL string,
) *ChainHandler {
	return &ChainHandler{
		proxy:                proxy,
		baseURLResolver:      baseURLResolver,
		serviceAuthInjector:  serviceAuthInjector,
		publisher:            publisher,
		FunctionsProviderURL: FunctionsProviderURL,
	}
}

func (ch ChainHandler) Run() {
	reqData := &chain.FunctionRequest{}
	for true {
		select {
		case dataByte := <-ch.publisher.Receive():
			logger.Info("receive request data", "value", string(dataByte))
			err := json.Unmarshal(dataByte, reqData)
			if err != nil {
				logger.Error("failed to unmarshal from the chain", "data", string(dataByte), "err", err)
				continue
			}
		}

		marshal, err := json.Marshal(reqData.Body)
		if err != nil {
			logger.Error("failed to unmarshal function request body", "err", err)
			continue
		}

		reqHttp, err := http.NewRequest(http.MethodPost, reqData.RequestURL, bytes.NewReader(marshal))
		if err != nil {
			logger.Error("failed to new http request", "err", err)
			continue
		}
		reqHttp.Header.Set("requestId", reqData.ReqId)
		baseURL := ch.FunctionsProviderURL
		if strings.HasSuffix(baseURL, "/") {
			baseURL = baseURL[0 : len(baseURL)-1]
		}
		ret := forwardRequestFromChain(reqHttp, ch.proxy.Client,
			baseURL, reqData.RequestURL, ch.proxy.Timeout, false, ch.serviceAuthInjector)
		ret.RequestId = reqData.ReqId
		ch.publisher.Reply(ret)
		if ret.Err != nil {
			logger.Error("failed to execute function", "err", string(ret.Err))
			continue
		}

		logger.Info("get result from function", "ret", ret)
	}

}
