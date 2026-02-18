#!/bin/bash
# Free port 8080 so you can run the backend with "go run ." or start docker compose.
# Usage: ./scripts/free-port-8080.sh
#
# Why "go run ." still fails after "docker compose down"? Docker only stops its
# containers. If you (or another terminal) started "go run ." earlier, that
# process is still running and keeps holding 8080. This script kills it.

PORT=8080
if command -v fuser &>/dev/null; then
  if fuser -k $PORT/tcp 2>/dev/null; then
    echo "Freed port $PORT."
  else
    echo "Nothing was using port $PORT."
  fi
  exit 0
fi
PID=$(lsof -ti :$PORT 2>/dev/null || true)
if [ -z "$PID" ]; then
  echo "Nothing is using port $PORT."
  exit 0
fi
echo "Killing PID(s) on $PORT: $PID"
kill $PID 2>/dev/null || kill -9 $PID 2>/dev/null
echo "Port $PORT should be free now."
