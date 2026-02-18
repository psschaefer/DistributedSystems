# TempConv2 – Temperature Converter (gRPC + Protocol Buffers)

# external ip: http://35.187.92.203/

Same as TempConv (Celsius ↔ Fahrenheit, Go backend, Flutter web frontend, GKE) but **using gRPC and Protocol Buffers** instead of REST/JSON.

- **Backend**: Go gRPC server (no database, two RPCs: `CelsiusToFahrenheit`, `FahrenheitToCelsius`)
- **Frontend**: Flutter web app using **gRPC-Web** to call the backend
- **Proxy**: Envoy for gRPC-Web ↔ gRPC (browser cannot speak raw gRPC)
- **Deployment**: Docker + Kubernetes (GKE, **linux/amd64**)




## Differences from TempConv (REST)

| Aspect        | TempConv   | TempConv2        |
|--------------|------------|------------------|
| API          | REST/JSON  | gRPC + Protobuf  |
| Backend      | HTTP server| gRPC server      |
| Frontend     | HTTP + JSON| gRPC-Web + proto  |
| Browser path | /api/*     | /grpc (via Envoy)|
| Load test    | k6 HTTP    | Go gRPC client   |

