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
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"go.opentelemetry.io/otel/trace"

	rotateLogs "github.com/lestrrat-go/file-rotatelogs"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Log is a simplified abstraction of the zap.Logger
type Log interface {
	Info(msg string, fields ...interface{})
	Error(msg string, fields ...interface{})
	Fatal(msg string, fields ...interface{})
	Debug(msg string, fields ...interface{})
	With(fields string) Log
	// For with trace
	For(ctx context.Context) Log
}

type Config struct {
	FileName  string `json:"file_name" mapstructure:"file_name,omitempty"`
	Level     string `json:"level" mapstructure:"level,omitempty"`
	OutputDir string `json:"output_dir" mapstructure:"output_dir,omitempty"`
}

const (
	defaultLogFileName = "defaas.log"
	loggerSkip         = 2
)

var (
	loggerObject *logger
	once         sync.Once
)

// logger delegates all calls to the underlying zap.Logger
type logger struct {
	zapSugaredLogger *zap.SugaredLogger
}

func init() {
	encoder := getEncoder()
	core := zapcore.NewCore(encoder, os.Stdout, zapcore.DebugLevel)
	zapLogger := zap.New(core, zap.AddCaller(), zap.AddCallerSkip(loggerSkip))
	loggerObject = &logger{zapLogger.Sugar()}
}

// Info logs an info msg with fields
func (l logger) Info(msg string, fields ...interface{}) {
	fmt.Println(fields)
	l.zapSugaredLogger.Infow(msg, fields...)
}

// Error logs an error msg with fields
func (l logger) Error(msg string, fields ...interface{}) {
	l.zapSugaredLogger.Errorw(msg, fields...)
}

// Fatal logs a fatal error msg with fields
func (l logger) Fatal(msg string, fields ...interface{}) {
	l.zapSugaredLogger.Fatalw(msg, fields...)
}

// Debug logs a fatal error msg with fields
func (l logger) Debug(msg string, fields ...interface{}) {
	l.zapSugaredLogger.Debugw(msg, fields...)
}

// With creates a child zapSugaredLogger, and optionally adds some context fields to that zapSugaredLogger.
func (l logger) With(fields string) Log {
	return logger{zapSugaredLogger: l.zapSugaredLogger.Named(fields)}
}

func (l logger) For(ctx context.Context) Log {
	span := trace.SpanFromContext(ctx)
	if span == nil {
		l.Debug("fail to found span")
		return l
	}
	tmpl := logger{l.zapSugaredLogger}
	tmpLogger := spanLogger{span: span, logger: tmpl}
	if span.IsRecording() {
		spanCtx := span.SpanContext()
		tmpLogger.logger = tmpl.With(spanCtx.TraceID().String()).With(spanCtx.SpanID().String())
	}
	return tmpLogger
}

// NewLogger config.OutputDir is empty, log is to output stdout
func NewLogger(config Config) *logger {
	writeSyncer := getLogWriter(config)
	encoder := getEncoder()
	logLevel := zapcore.DebugLevel
	switch strings.ToLower(config.Level) {
	case "info":
		logLevel = zapcore.InfoLevel
	case "warn":
		logLevel = zapcore.WarnLevel
	}

	once.Do(func() {
		core := zapcore.NewCore(encoder, writeSyncer, logLevel)
		zapLogger := zap.New(core, zap.AddCaller(), zap.AddCallerSkip(loggerSkip))

		loggerObject = &logger{zapLogger.Sugar()}
	})

	return loggerObject
}

func getEncoder() zapcore.Encoder {
	encoderConfig := zap.NewProductionEncoderConfig()
	encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	encoderConfig.EncodeLevel = zapcore.CapitalLevelEncoder
	return zapcore.NewConsoleEncoder(encoderConfig)
}

func getLogWriter(config Config) zapcore.WriteSyncer {
	if config.OutputDir == "" {
		return zapcore.AddSync(os.Stdout)
	}
	fileName := config.FileName
	if fileName == "" {
		fileName = defaultLogFileName
	}

	hook, err := rotateLogs.New(
		strings.Replace(filepath.Join(config.OutputDir, fileName), ".log", "", -1)+"-%Y%m%d%H.log",
		rotateLogs.WithMaxAge(time.Hour*24*7),
		rotateLogs.WithRotationTime(time.Hour*24),
	)
	if err != nil {
		panic(fmt.Errorf("init log hook, %v", err))
	}

	return zapcore.AddSync(hook)
}
