// Copyright (c) 2019 The Jaeger Authors.
// Copyright (c) 2017 Uber Technologies, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package logger

import (
	"context"
	"fmt"

	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/trace"
)

type spanLogger struct {
	logger     Log
	span       trace.Span
	spanFields []interface{}
}

func (sl spanLogger) Debug(msg string, fields ...interface{}) {
	sl.logToSpan("debug", msg, fields...)
	sl.logger.Debug(msg, append(sl.spanFields, fields...)...)
}

func (sl spanLogger) Info(msg string, fields ...interface{}) {
	sl.logToSpan("info", msg, fields...)
	sl.logger.Info(msg, append(sl.spanFields, fields...)...)
}

func (sl spanLogger) Error(msg string, fields ...interface{}) {
	sl.logToSpan("error", msg, fields...)
	sl.logger.Error(msg, append(sl.spanFields, fields...)...)
}

func (sl spanLogger) Fatal(msg string, fields ...interface{}) {
	sl.logToSpan("fatal", msg, fields...)
	sl.logger.Fatal(msg, append(sl.spanFields, fields...)...)
}

// With creates a child zapSugaredLogger, and optionally adds some context fields to that zapSugaredLogger.
func (sl spanLogger) With(fields string) Log {
	return spanLogger{logger: sl.logger.With(fields), span: sl.span, spanFields: sl.spanFields}
}

func (sl spanLogger) For(ctx context.Context) Log {
	return sl
}

func (sl spanLogger) logToSpan(level string, eventMsg string, fields ...interface{}) {
	if len(fields)%2 > 0 {
		sl.logger.Error("the number of fields must be a multiple of 2")
		fields = append(fields, "the number of fields must be a multiple of 2")
	}
	// TODO rather than always converting the fields, we could wrap them into a lazy zapSugaredLogger
	fa := fieldAdapter(make([]attribute.KeyValue, 0, 2+len(fields)))
	fa = append(fa, attribute.String("level", level))

	for i := 0; i+1 < len(fields); i += 2 {
		fa = append(fa, attribute.String(fmt.Sprintf("%v", fields[i]), fmt.Sprintf("%v", fields[i+1])))
	}
	sl.span.AddEvent(eventMsg, trace.WithAttributes(fa...))
}

type fieldAdapter []attribute.KeyValue
