#!/bin/bash
# Regenerate Go code from proto using Docker (no local protoc needed).
set -e
cd "$(dirname "$0")/.."
BACKEND=backend
PROTO=proto
GEN=$BACKEND/gen

# Use Docker to run protoc with Go plugins
docker run --rm -v "$(pwd):/workspace" -w /workspace \
  golang:1.22-bookworm \
  bash -c '
    apt-get update -qq && apt-get install -y -qq unzip > /dev/null
    curl -sSL -o /tmp/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v28.2/protoc-28.2-linux-x86_64.zip
    unzip -o -q /tmp/protoc.zip -d /usr/local bin/protoc include/*
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.2
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
    export PATH="$PATH:$(go env GOPATH)/bin"
    protoc -I '"$PROTO"' \
      --go_out='"$BACKEND"' --go_opt=module=tempconv2-backend \
      --go-grpc_out='"$BACKEND"' --go-grpc_opt=module=tempconv2-backend \
      '"$PROTO"'/tempconv.proto
  '

# protoc with go_package=gen puts output in backend/gen/ when using paths=source_relative or default
# Default (without source_relative) uses go_package path, so we get backend/gen/ if go_package is "gen"
if [ -d "$BACKEND/gen" ]; then
  echo "Generated files in $BACKEND/gen/"
  ls -la "$BACKEND/gen/"
else
  # Some protoc versions put under backend/tempconv/ based on package name
  if [ -d "$BACKEND/tempconv" ]; then
    mkdir -p "$GEN"
    mv "$BACKEND/tempconv/"*.go "$GEN/"
    rmdir "$BACKEND/tempconv" 2>/dev/null || true
    echo "Moved generated files to $GEN/"
  fi
fi
