package logger

import (
	"context"

	"go.opentelemetry.io/otel/trace"
)

// Info logs an info msg with fields
func Info(msg string, fields ...interface{}) {

	loggerObject.Info(msg, fields...)
}

// Error logs an error msg with fields
func Error(msg string, fields ...interface{}) {
	loggerObject.Error(msg, fields...)
}

// Fatal logs a fatal error msg with fields
func Fatal(msg string, fields ...interface{}) {
	loggerObject.Fatal(msg, fields...)
}

// Debug logs a fatal error msg with fields
func Debug(msg string, fields ...interface{}) {
	loggerObject.Debug(msg, fields...)
}

func With(fields string) Log {
	return logger{zapSugaredLogger: loggerObject.zapSugaredLogger.Named(fields)}
}

func For(ctx context.Context) Log {
	span := trace.SpanFromContext(ctx)
	if span == nil {
		loggerObject.Debug("fail to found span")
		return loggerObject
	}
	tmpl := logger{loggerObject.zapSugaredLogger}
	tmpLogger := spanLogger{span: span, logger: tmpl}
	if span.IsRecording() {
		spanCtx := span.SpanContext()
		tmpLogger.logger = tmpl.With(spanCtx.TraceID().String()).With(spanCtx.SpanID().String())
	}
	return tmpLogger
}
