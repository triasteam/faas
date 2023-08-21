// Copyright (c) OpenFaaS Author(s). All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for full license information.

package handlers

import (
	"fmt"
	"net/http"

	"github.com/openfaas/faas/gateway/logger"
	"github.com/openfaas/faas/gateway/pkg/middleware"
	"github.com/openfaas/faas/gateway/scaling"
)

// MakeScalingHandler creates handler which can scale a function from
// zero to N replica(s). After scaling the next http.HandlerFunc will
// be called. If the function is not ready after the configured
// amount of attempts / queries then next will not be invoked and a status
// will be returned to the client.
func MakeScalingHandler(next http.HandlerFunc, scaler scaling.FunctionScaler, config scaling.ScalingConfig, defaultNamespace string) http.HandlerFunc {

	return func(w http.ResponseWriter, r *http.Request) {

		functionName, namespace := middleware.GetNamespace(defaultNamespace, middleware.GetServiceName(r.URL.String()))

		res := scaler.Scale(functionName, namespace)

		if !res.Found {
			errStr := fmt.Sprintf("error finding function %s.%s: %s", functionName, namespace, res.Error.Error())
			logger.Info("Scaling", "err", errStr)

			w.WriteHeader(http.StatusNotFound)
			w.Write([]byte(errStr))
			return
		}

		if res.Error != nil {
			errStr := fmt.Sprintf("error finding function %s.%s: %s", functionName, namespace, res.Error.Error())
			logger.Info("Scaling", "err", errStr)

			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte(errStr))
			return
		}

		if res.Available {
			next.ServeHTTP(w, r)
			return
		}

		logger.Info("[Scale]  timed-outs",
			"functionName", functionName, "namespace", namespace, "timed-out", res.Duration.Seconds())
	}
}
