package types

import (
	"time"

	"github.com/openfaas/faas/gateway/logger"
)

type routine func(attempt int) error

func Retry(r routine, label string, attempts int, interval time.Duration) error {
	var err error

	for i := 0; i < attempts; i++ {
		res := r(i)
		if res != nil {
			err = res
			logger.Info("retry times", "label", label, "times", i, "attempts", attempts, "error", res)
		} else {
			err = nil
			break
		}
		time.Sleep(interval)
	}
	return err
}
