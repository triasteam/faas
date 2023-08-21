package metrics

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"os"
	"testing"
	"time"

	"github.com/openfaas/faas-provider/types"
)

func TestVerifierReporter_SendFunctions(t *testing.T) {
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		dump, err := httputil.DumpRequest(r, true)
		if err != nil {
			http.Error(w, fmt.Sprint(err), http.StatusInternalServerError)
			return
		}

		fmt.Fprintf(w, "%q", dump)
	}))

	defer ts.Close()
	fmt.Println("server ", ts.URL)
	os.Setenv(envFaasNodeAddress, "0x98723945873953453w")
	os.Setenv(envFaasVerifierProvider, ts.URL)

	vr, err := NewVerifierReporter()
	if err != nil {
		t.Error(err)
		return
	}

	for i := 0; i < 20; i++ {
		vr.SendFunctions([]types.FunctionStatus{{Name: fmt.Sprintf("%d", i)}})
		time.Sleep(time.Microsecond * 10)
	}
	time.Sleep(10 * time.Second)
}
