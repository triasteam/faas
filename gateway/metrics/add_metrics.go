package metrics

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strconv"

	types "github.com/openfaas/faas-provider/types"
	"github.com/openfaas/faas/gateway/logger"
)

// AddMetricsHandler wraps a http.HandlerFunc with Prometheus metrics
func AddMetricsHandler(handler http.HandlerFunc, prometheusQuery PrometheusQueryFetcher) http.HandlerFunc {

	return func(w http.ResponseWriter, r *http.Request) {

		recorder := httptest.NewRecorder()
		handler.ServeHTTP(recorder, r)
		upstreamCall := recorder.Result()

		if upstreamCall.Body == nil {
			logger.Info("Upstream call had empty body.")
			return
		}

		defer upstreamCall.Body.Close()
		upstreamBody, _ := ioutil.ReadAll(upstreamCall.Body)

		if recorder.Code != http.StatusOK {
			logger.Info("List functions responded", "code",
				recorder.Code,
				"body", string(upstreamBody))
			http.Error(w, string(upstreamBody), recorder.Code)
			return
		}

		var functions []types.FunctionStatus

		err := json.Unmarshal(upstreamBody, &functions)
		if err != nil {
			logger.Info("Metrics upstream error", "error", err, "value", string(upstreamBody))

			http.Error(w, "Unable to parse list of functions from provider", http.StatusInternalServerError)
			return
		}

		// Ensure values are empty first.
		for i := range functions {
			functions[i].InvocationCount = 0
		}

		if len(functions) > 0 {

			ns := functions[0].Namespace
			q := fmt.Sprintf(`sum(gateway_function_invocation_total{function_name=~".*.%s"}) by (function_name)`, ns)
			// Restrict query results to only function names matching namespace suffix.

			results, err := prometheusQuery.Fetch(url.QueryEscape(q))
			if err != nil {
				// log the error but continue, the mixIn will correctly handle the empty results.
				logger.Info("Error querying Prometheus", "err", err.Error())
			}
			mixIn(&functions, results)
		}

		bytesOut, err := json.Marshal(functions)
		if err != nil {
			logger.Info("Error serializing functions", "err", err)
			http.Error(w, "Error writing response after adding metrics", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write(bytesOut)
	}
}

func mixIn(functions *[]types.FunctionStatus, metrics *VectorQueryResponse) {

	if functions == nil {
		return
	}

	for i, function := range *functions {
		for _, v := range metrics.Data.Result {

			if v.Metric.FunctionName == fmt.Sprintf("%s.%s", function.Name, function.Namespace) {
				metricValue := v.Value[1]
				switch value := metricValue.(type) {
				case string:
					f, err := strconv.ParseFloat(value, 64)
					if err != nil {
						logger.Info("add_metrics: unable to convert value for metric:", "value", value, "metric", err)
						continue
					}
					(*functions)[i].InvocationCount += f
				}
			}
		}
	}
}
