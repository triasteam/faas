package logger

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

var (
	jaegerUrl = "http://101.251.211.203:14268/api/traces"
)

func TestNewLogger(t *testing.T) {
	tLogger := NewLogger(Config{
		FileName:  "test",
		Level:     "debug",
		OutputDir: "",
	})
	tLogger.Info("test", "info", "this is a test")
}

func TestNewTraceProvider(t *testing.T) {
	tracerP := NewTracerProvider(jaegerUrl, "test-ns", "test")
	// Cleanly shutdown and flush telemetry when the application exits.
	ctx := context.Background()
	defer func(ctx context.Context) {
		err := tracerP.Shutdown(ctx)
		if err != nil {
			panic(err)
		}
	}(ctx)

	tLogger := NewLogger(Config{
		FileName:  "test",
		Level:     "debug",
		OutputDir: "",
	})

	ctx, span := tracerP.GetProvider().Tracer("test").Start(ctx, "testSpan")

	defer span.End()
	wait := sync.WaitGroup{}
	wait.Add(2)
	go func() {

		defer wait.Done()
		tLogger.For(ctx).Info("haha2", "msg3", "this is s test")
	}()
	go func() {
		defer wait.Done()

		tLogger.For(ctx).Info("haha2", "msg4", "this is s test")

	}()
	wait.Wait()
}

func TestHttpServiceWithJaeger(t *testing.T) {
	ExampleServer()
}

func ExampleServer() {
	tp := NewTracerProvider(jaegerUrl, "test-http-server1", "test")
	// Cleanly shutdown and flush telemetry when the application exits.

	defer func() {
		err := tp.Shutdown(context.Background())
		if err != nil {
			panic(err)
		}
	}()
	tLogger := NewLogger(Config{
		FileName:  "test",
		Level:     "debug",
		OutputDir: "",
	})

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		traceTagID := "123456"
		opts := []trace.SpanStartOption{
			trace.WithAttributes(attribute.String(traceTagID, "123214523")),
		}
		tpP := tp.GetProvider().Tracer("test http")
		ctx, span := tpP.Start(context.Background(), "httpSpan", opts...)
		defer span.End()
		_, err := fmt.Fprintln(w, "Hello, client, this a test case")
		if err != nil {
			return
		}

		_, _ = MakeOutgoingRequest(ctx, r, tpP, "new request")
		tLogger.For(ctx).Error("haha2", "msg3", "this is s test")
		log.Println(r.Header)
	}))
	defer ts.Close()

	res, err := http.Get(ts.URL)
	if err != nil {
		log.Fatal(err)
		return
	}
	fmt.Println(res.Header)
	greeting, err := io.ReadAll(res.Body)
	res.Body.Close()
	if err != nil {
		log.Fatal(err)
		return
	}

	fmt.Printf("%s", greeting)
	/*Output: Hello, client, this a test case*/
}
