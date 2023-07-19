// Copyright (c) OpenFaaS Author(s). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

package handlers

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"time"

	"github.com/openfaas/faas/gateway/chain/logger"
	"github.com/openfaas/faas/gateway/pkg/middleware"
	"github.com/openfaas/faas/gateway/types"
)

const CallID = "X-Call-Id"

// MakeForwardingProxyHandler create a handler which forwards HTTP requests
func MakeForwardingProxyHandler(proxy *types.HTTPClientReverseProxy,
	notifiers []HTTPNotifier,
	baseURLResolver middleware.BaseURLResolver,
	urlPathTransformer middleware.URLPathTransformer,
	serviceAuthInjector middleware.AuthInjector) http.HandlerFunc {

	writeRequestURI := false
	if _, exists := os.LookupEnv("write_request_uri"); exists {
		writeRequestURI = exists
	}

	return func(w http.ResponseWriter, r *http.Request) {
		baseURL := baseURLResolver.Resolve(r)
		originalURL := r.URL.String()
		requestURL := urlPathTransformer.Transform(r)

		for _, notifier := range notifiers {
			notifier.Notify(r.Method, requestURL, originalURL, http.StatusProcessing, "started", time.Second*0)
		}
		logger.Info("proxy handler", "uid", r.Header.Get(CallID), "requestURL", requestURL, "originalURL", originalURL, "baseURL", baseURL)
		start := time.Now()

		statusCode, err := forwardRequest(w, r, proxy.Client, baseURL, requestURL, proxy.Timeout, writeRequestURI, serviceAuthInjector)

		seconds := time.Since(start)
		if err != nil {
			logger.Error("error with upstream request to", "uid", r.Header.Get(CallID), "request_url", requestURL, "err", err.Error())
		}

		for _, notifier := range notifiers {
			notifier.Notify(r.Method, requestURL, originalURL, statusCode, "completed", seconds)
		}
	}
}

func buildUpstreamRequest(r *http.Request, baseURL string, requestURL string) *http.Request {
	url := baseURL + requestURL

	if len(r.URL.RawQuery) > 0 {
		url = fmt.Sprintf("%s?%s", url, r.URL.RawQuery)
	}
	logger.Info("build upstream request", "uid", r.Header.Get(CallID), "url", url)
	logger.Info("build upstream request", "uid", r.Header.Get(CallID), "header", r.Header)
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

func forwardRequest(w http.ResponseWriter,
	r *http.Request,
	proxyClient *http.Client,
	baseURL string,
	requestURL string,
	timeout time.Duration,
	writeRequestURI bool,
	serviceAuthInjector middleware.AuthInjector) (int, error) {

	logger.Info("forward request", "uid", r.Header.Get(CallID), "baseURL", baseURL, "requestURL", requestURL)

	upstreamReq := buildUpstreamRequest(r, baseURL, requestURL)
	if upstreamReq.Body != nil {
		defer upstreamReq.Body.Close()
	}

	if serviceAuthInjector != nil {
		serviceAuthInjector.Inject(upstreamReq)
	}

	if writeRequestURI {
		logger.Info("forwardRequest", "host", upstreamReq.Host, "url", upstreamReq.URL.String())
	}

	ctx, cancel := context.WithTimeout(r.Context(), timeout)
	defer cancel()

	res, resErr := proxyClient.Do(upstreamReq.WithContext(ctx))
	if resErr != nil {
		badStatus := http.StatusBadGateway
		w.WriteHeader(badStatus)
		return badStatus, resErr
	}

	if res.Body != nil {
		defer res.Body.Close()
	}

	copyHeaders(w.Header(), &res.Header)

	// Write status code
	w.WriteHeader(res.StatusCode)

	if res.Body != nil {
		// Copy the body over
		io.CopyBuffer(w, res.Body, nil)
	}

	return res.StatusCode, nil
}

func copyHeaders(destination http.Header, source *http.Header) {
	for k, v := range *source {
		vClone := make([]string, len(v))
		copy(vClone, v)
		(destination)[k] = vClone
	}
}

func deleteHeaders(target *http.Header, exclude *[]string) {
	for _, h := range *exclude {
		target.Del(h)
	}
}

// Hop-by-hop headers. These are removed when sent to the backend.
// As of RFC 7230, hop-by-hop headers are required to appear in the
// Connection header field. These are the headers defined by the
// obsoleted RFC 2616 (section 13.5.1) and are used for backward
// compatibility.
// Copied from: https://golang.org/src/net/http/httputil/reverseproxy.go
var hopHeaders = []string{
	"Connection",
	"Proxy-Connection", // non-standard but still sent by libcurl and rejected by e.g. google
	"Keep-Alive",
	"Proxy-Authenticate",
	"Proxy-Authorization",
	"Te",      // canonicalized version of "TE"
	"Trailer", // not Trailers per URL above; https://www.rfc-editor.org/errata_search.php?eid=4522
	"Transfer-Encoding",
	"Upgrade",
}
