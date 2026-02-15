# TempConv2 – Temperature Converter (gRPC + Protocol Buffers)

Same as TempConv (Celsius ↔ Fahrenheit, Go backend, Flutter web frontend, GKE) but **using gRPC and Protocol Buffers** instead of REST/JSON.

- **Backend**: Go gRPC server (no database, two RPCs: `CelsiusToFahrenheit`, `FahrenheitToCelsius`)
- **Frontend**: Flutter web app using **gRPC-Web** to call the backend
- **Proxy**: Envoy for gRPC-Web ↔ gRPC (browser cannot speak raw gRPC)
- **Deployment**: Docker + Kubernetes (GKE, **linux/amd64**)

---

## Project structure

```
TempConv2/
├── proto/
│   └── tempconv.proto          # Protocol Buffer + gRPC service
├── backend/                    # Go gRPC server
│   ├── main.go
│   ├── gen/                    # Generated Go from proto (or run scripts/gen-go.sh)
│   │   ├── tempconv.pb.go
│   │   └── tempconv_grpc.pb.go
│   ├── envoy.yaml              # Envoy config (K8s sidecar: 127.0.0.1:9090)
│   ├── envoy.docker.yaml       # Envoy config (docker-compose: backend:9090)
│   └── Dockerfile
├── frontend/                   # Flutter web, gRPC-Web client
│   ├── lib/
│   │   ├── main.dart
│   │   ├── grpc_client.dart
│   │   ├── generated/          # Hand-written proto-compatible + client stub
│   │   │   ├── tempconv.pb.dart
│   │   │   └── tempconv_grpc.dart
│   │   └── screens/
│   ├── nginx.conf              # For K8s: proxy /grpc -> backend:8080
│   ├── nginx.docker.conf       # For docker-compose: proxy /grpc -> envoy:8080
│   └── Dockerfile
├── k8s/
│   ├── namespace.yaml
│   ├── backend-deployment.yaml   # Backend + Envoy sidecar + ConfigMap
│   ├── frontend-deployment.yaml
│   └── hpa.yaml
├── loadtest/
│   ├── loadtest.go             # Go gRPC load test
│   ├── go.mod
│   └── README.md
├── scripts/
│   ├── gen-go.sh               # Regenerate Go from proto (needs protoc)
│   ├── build-and-push.sh
│   ├── deploy-to-gke.sh
│   └── create-gke-cluster.sh
├── docker-compose.yml
└── README.md
```

---

## Step-by-step guide

### Prerequisites

- Docker & Docker Compose
- Go 1.22+
- Flutter SDK (for local frontend dev)
- **gcloud** CLI (for GKE)
- **kubectl**
- (Optional) **protoc** + **protoc-gen-go** + **protoc-gen-go-grpc** to regenerate Go from proto

---

### Local testing (step-by-step)

**Prerequisites:** Docker and Docker Compose installed.

1. **Open a terminal and go to the project**
   ```bash
   cd /path/to/TempConv2
   ```

2. **Start all services (frontend, backend, Envoy)**
   ```bash
   docker compose up --build
   ```
   Wait until you see lines like `frontend ... done` and the containers are running. (Use `docker compose up --build -d` to run in the background.)

3. **Open the app in the browser**
   - Go to **http://localhost** (port 80).
   - You should see the TempConv2 (gRPC) temperature converter.

4. **Test the conversion**
   - Enter a number (e.g. `25`).
   - Click **Convert**.
   - You should see a result like `25.00°C = 77.00°F`. If you see an error, the UI will show the message; check that all three containers are running with `docker compose ps`.

5. **Optional: test the backend directly with grpcurl**
   ```bash
   grpcurl -plaintext -d '{"value": 25}' localhost:9090 tempconv.TempConvService/CelsiusToFahrenheit
   grpcurl -plaintext -d '{"value": 77}' localhost:9090 tempconv.TempConvService/FahrenheitToCelsius
   ```

6. **Stop everything**
   - If you ran without `-d`: press **Ctrl+C**, then run `docker compose down`.
   - If you ran with `-d`: run `docker compose down`.

---

### Step 1: Local development with Docker Compose (reference)

All images are built for **linux/amd64** (GKE nodes).

```bash
cd TempConv2
docker compose up --build -d
```

- **Frontend**: http://localhost (port 80)  
- **Backend gRPC**: localhost:9090 (for load test or grpcurl)  
- **Envoy gRPC-Web**: localhost:8080  

The Flutter app calls `/tempconv.TempConvService/...`, which nginx proxies to Envoy; Envoy forwards to the Go gRPC server.

Stop: `docker compose down`

---

### Step 2: Regenerate Go from proto (optional)

If you change `proto/tempconv.proto`, regenerate Go:

**Option A – using Docker (no local protoc):**
```bash
./scripts/gen-go-docker.sh
```

**Option B – with local protoc and Go plugins:**
```bash
# go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
# go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
./scripts/gen-go.sh
```

The repo ships generated Go in `backend/gen/` so you can build without running this.

---

### Step 3: Build and run backend locally (without Docker)

```bash
cd backend
go mod tidy
go run .
# gRPC on :9090, health on :9091
```

In another terminal, run the Flutter web app (pointing at Envoy for gRPC-Web):

```bash
cd frontend
flutter pub get
flutter run -d chrome
# Use baseUrl that reaches Envoy, e.g. http://localhost:8080 for Envoy
```

If you run only the Go server (no Envoy), the browser cannot call it directly (no gRPC-Web). So for local UI testing, use Docker Compose or run Envoy separately with `envoy.docker.yaml`.

---

### Step 4: Build Docker images for GKE (amd64)

Use your **GCP project ID**:

```bash
export PROJECT_ID=your-gcp-project-id
./scripts/build-and-push.sh $PROJECT_ID
```

This builds and pushes:

- `gcr.io/$PROJECT_ID/tempconv2-backend:latest`
- `gcr.io/$PROJECT_ID/tempconv2-frontend:latest`

Both are **linux/amd64**.

---

### Step 5: Create a GKE cluster (amd64)

```bash
./scripts/create-gke-cluster.sh $PROJECT_ID tempconv2-cluster europe-west1-b
```

This creates a cluster with autoscaling; nodes are amd64 by default.

---

### Step 6: Deploy to GKE

```bash
./scripts/deploy-to-gke.sh $PROJECT_ID tempconv2-cluster europe-west1-b
```

The script:

1. Gets cluster credentials  
2. Replaces `PROJECT_ID` in `k8s/backend-deployment.yaml` and `k8s/frontend-deployment.yaml`  
3. Applies namespace, backend (with Envoy sidecar), frontend, and HPA  

Then wait for the frontend `LoadBalancer` external IP:

```bash
kubectl get svc frontend -n tempconv2
# Open http://<EXTERNAL-IP>
```

---

### Step 7: Load testing (gRPC)

The load test uses the **gRPC** port (direct to the backend), not gRPC-Web.

**Locally (backend on 9090):**

```bash
cd loadtest
go mod tidy
go run . -target localhost:9090 -c 10 -n 1000
```

**Against a backend in the cluster** (e.g. via port-forward or a NodePort/LoadBalancer for 9090):

```bash
kubectl port-forward -n tempconv2 svc/backend 9090:8080 9091:9091
# Then run load test against localhost:9090; note the gRPC port in-cluster is 9090 on the pod, but the Service exposes 8080 (Envoy). So either:
# - Port-forward the backend pod directly to 9090, or
# - Add a separate Service port 9090 to the backend and use that for load test.
```

For simplicity you can port-forward a backend pod:

```bash
kubectl port-forward -n tempconv2 deployment/backend 9090:9090 9091:9091
# In another terminal:
cd loadtest && go run . -target localhost:9090 -c 20 -n 2000
```

(Flags: `-target`, `-c`, `-n`; see `loadtest/README.md`.)

---

## API (gRPC)

- **Service**: `tempconv.TempConvService`
- **RPCs**:
  - `CelsiusToFahrenheit(ConversionRequest) returns (ConversionResponse)`
  - `FahrenheitToCelsius(ConversionRequest) returns (ConversionResponse)`
- **Messages**: `ConversionRequest` (field `value` double), `ConversionResponse` (input, output, from_unit, to_unit, description)

---

## Architecture (gRPC + gRPC-Web)

```
Browser (Flutter)  --gRPC-Web (HTTP/1.1)-->  Nginx  -->  Envoy  --gRPC (HTTP/2)-->  Go backend
                       /grpc                    :80       :8080                        :9090
```

- **K8s**: Backend deployment has two containers (Go app + Envoy sidecar). Service exposes 8080 (Envoy) and 9091 (health). Frontend nginx proxies `/grpc` to `backend:8080`.
- **Docker Compose**: Separate Envoy container; frontend uses `nginx.docker.conf` and proxies `/grpc` to `envoy:8080`; Envoy uses `envoy.docker.yaml` and forwards to `backend:9090`.

---

## Differences from TempConv (REST)

| Aspect        | TempConv   | TempConv2        |
|--------------|------------|------------------|
| API          | REST/JSON  | gRPC + Protobuf  |
| Backend      | HTTP server| gRPC server      |
| Frontend     | HTTP + JSON| gRPC-Web + proto  |
| Browser path | /api/*     | /grpc (via Envoy)|
| Load test    | k6 HTTP    | Go gRPC client   |

---

## License

MIT
