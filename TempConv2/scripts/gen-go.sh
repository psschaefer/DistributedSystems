#!/bin/bash
# Regenerate Go code from proto. Requires protoc, protoc-gen-go, protoc-gen-go-grpc.
set -e
cd "$(dirname "$0")/.."
BACKEND=backend
PROTO=proto
GEN=$BACKEND/gen
mkdir -p "$GEN"
protoc -I "$PROTO" \
  --go_out="$BACKEND" --go_opt=module=tempconv2-backend \
  --go-grpc_out="$BACKEND" --go-grpc_opt=module=tempconv2-backend \
  "$PROTO"/tempconv.proto
# Move generated files into gen/ if protoc put them elsewhere
if [ -f "$BACKEND/tempconv/tempconv.pb.go" ]; then
  mv "$BACKEND/tempconv/"*.go "$GEN/"
  rmdir "$BACKEND/tempconv" 2>/dev/null || true
fi
