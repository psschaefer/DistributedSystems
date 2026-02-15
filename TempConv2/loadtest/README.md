# gRPC load test for TempConv2

Uses the same Go gRPC client as the backend to hit the **gRPC** port (not gRPC-Web).

## Usage

```bash
go mod tidy
go run . [flags]
```

Flags:

- `-target`: Backend gRPC address (default `localhost:9090`)
- `-c`: Concurrent workers (default 10)
- `n`: Total requests (default 1000)

Examples:

```bash
# Local backend
go run . -target localhost:9090 -c 10 -n 1000

# After port-forward to a backend pod
kubectl port-forward -n tempconv2 deployment/backend 9090:9090 9091:9091
go run . -target localhost:9090 -c 20 -n 2000
```
