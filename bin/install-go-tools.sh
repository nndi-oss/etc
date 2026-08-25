#!/bin/sh
# How to run this curl -sSL https://raw.github/nndi-oss/install-go-tools.sh | bash

# govulncheck
go install golang.org/x/vuln/cmd/govulncheck@latest

# goda
go install github.com/loov/goda@latest

# golangci-lint
curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b $(go env GOPATH)/bin v2.12.2

# go-size-analyzer
go install github.com/Zxilly/go-size-analyzer/cmd/gsa@latest

