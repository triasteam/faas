package main

import (
	"fmt"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/gorilla/mux"
)

func TestAAA(t *testing.T) {
	r := mux.NewRouter()
	r.HandleFunc("/function/{name:["+NameExpression+"]+}", func(writer http.ResponseWriter, request *http.Request) {
		request.ParseForm()
		fmt.Println(request.Header.Get("names"))
		fmt.Println(request.Header)
		fmt.Println(request.Form)
		vars := mux.Vars(request)
		fmt.Println(vars)

	}).Methods(http.MethodGet)

	s := &http.Server{
		Addr: fmt.Sprintf(":%d", 8383),

		MaxHeaderBytes: http.DefaultMaxHeaderBytes, // 1MB - can be overridden by setting Server.MaxHeaderBytes.
		Handler:        r,
	}
	go func() {
		err := s.ListenAndServe()
		if err != nil {
			t.Error(err.Error())
			return
		}
	}()
	time.Sleep(time.Second * 2)
	req, err := http.NewRequest(http.MethodGet, "http://127.0.0.1:8383/function/test", nil)
	if err != nil {
		t.Error(err.Error())
		return
	}
	do, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Error(err.Error())
		return
	}

	bs, err := io.ReadAll(do.Body)
	if err != nil {
		t.Fatal(err)
	}
	fmt.Println(string(bs))
}
