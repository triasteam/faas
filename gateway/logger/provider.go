package logger

import (
	"context"
	"net/http"
	"time"

	"github.com/pkg/errors"
	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/trace"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/jaeger"
	"go.opentelemetry.io/otel/sdk/resource"
	tracesdk "go.opentelemetry.io/otel/sdk/trace"
	semconv "go.opentelemetry.io/otel/semconv/v1.4.0"
)

var (
	tracer *tracesdk.TracerProvider
	//tracerOnce sync.Once
)

func GetProvider() trace.TracerProvider {
	return tracer
}

type tracerProvider struct{}

func (t tracerProvider) GetProvider() trace.TracerProvider {
	return tracer
}

// NewTracerProvider register with jaeger url, example "http://localhost:14268/api/traces"
// envType explains what environment the serviceName server run in
func NewTracerProvider(tpUrl string, serviceName, envType string) *tracerProvider {

	var err error
	if tpUrl == "" {
		loggerObject.Error("log tracing url is empty")
	}

	var exp *jaeger.Exporter
	// Create the Jaeger exporter
	exp, err = jaeger.New(jaeger.WithCollectorEndpoint(jaeger.WithEndpoint(tpUrl)))
	if err != nil {
		panic(errors.WithMessage(err, "cannot create jaeger provider"))
	}

	tracer = tracesdk.NewTracerProvider(
		// Always be sure to batch in production.
		tracesdk.WithBatcher(exp),
		// Record information about this application in a Resource.
		tracesdk.WithResource(resource.NewWithAttributes(
			semconv.SchemaURL,
			semconv.ServiceNameKey.String(serviceName),
			attribute.String("environment", envType),
			//attribute.Int64("ID", svcID),
		)),
	)

	otel.SetTracerProvider(tracer)
	otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(propagation.TraceContext{}, propagation.Baggage{}))

	if tracer == nil {
		panic(errors.WithMessage(err, "failed to init zapSugaredLogger tracer"))
	}

	return &tracerProvider{}
}

func (t tracerProvider) Shutdown(ctx context.Context) error {
	// Do not make the application hang when it is shutdown.
	ctx, cancel := context.WithTimeout(ctx, time.Second*5)
	defer cancel()

	return tracer.Shutdown(ctx)
}

// MakeOutgoingRequest mimics what an instrumented http client does.
func MakeOutgoingRequest(ctx context.Context, req *http.Request, tp trace.Tracer, name string) (context.Context, trace.Span) {
	//make a new http request
	if req == nil {
		panic("http request is nil")
	}
	if tp == nil {
		tp = otel.GetTracerProvider().Tracer(name)
	}

	ctx, span := tp.Start(ctx, name)

	loggerObject.For(ctx).Info("span is recorded")
	req = req.WithContext(ctx)
	otel.GetTextMapPropagator().Inject(ctx, propagation.HeaderCarrier(req.Header))
	return ctx, span
}

func ExtractRequestSpan(spanName string, req *http.Request, tp trace.Tracer) (context.Context, trace.Span) {
	if req == nil {
		panic("http request is nil")
	}
	ctx := otel.GetTextMapPropagator().Extract(req.Context(), propagation.HeaderCarrier(req.Header))

	return tp.Start(ctx, spanName)
}

func ExtractRequestContext(req *http.Request) context.Context {
	if req == nil {
		panic("http request is nil")
	}
	ctx := otel.GetTextMapPropagator().Extract(req.Context(), propagation.HeaderCarrier(req.Header))

	return ctx
}
