# Texas Hold'em (REST API + Flutter Web)_
REST API and web UI for Texas Hold'em: hand evaluation, hand comparison, and win probability (Monte Carlo). Same deployment pattern as TempConv: Go backend, Flutter web, Kubernetes with **own external IP** (namespace `texashold`),test cases are in hand_test

## Card format

Each card is **2 characters**: suit + rank.

- **Suits:** H (Hearts), S (Spades), D (Diamonds), C (Clubs)
- **Ranks:** A, 2–9, T, J, Q, K

Examples: `HA` (Ace of Hearts), `S7` (Seven of Spades), `CT` (Ten of Clubs).

## API (REST, JSON)

Base path: `/api`

| Endpoint | Method | Request body | Response |
|----------|--------|--------------|----------|
| `/api/evaluate` | POST | `hole_cards` (2 strings), `community_cards` (5 strings) | `best_hand`, `hand_type` |
| `/api/compare` | POST | `hand1` / `hand2`, each with `hole_cards` (2) and `community_cards` (5) | `hand1_best`, `hand1_type`, `hand2_best`, `hand2_type`, `winner` ("hand1" \| "hand2" \| "tie") |
| `/api/win-probability` | POST | `hole_cards` (2), `community_cards` (0/3/4/5), `num_players`, `num_simulations` | `win_probability` (0–1), `description` |

## Local run

**Option 1: Backend + Flutter (good for dev)**

1. Start the backend (in one terminal):

```bash
cd texasHold/backend
go run .
# API on http://localhost:8080
```

2. Run the Flutter app (in another terminal):

```bash
cd texasHold/frontend
flutter pub get
flutter run -d chrome
```

In debug mode the app calls `http://localhost:8080` for the API (CORS is enabled). Open the URL Flutter prints (e.g. http://localhost:XXXX).

**Option 2: Docker Compose (production-like)**

```bash
cd texasHold
docker compose up --build
# Then open http://localhost (frontend); backend at :8080
```

**Port 8080 already in use / "go run ." fails after docker compose down**

Docker only stops its own containers. A **previous** `go run .` (or any other process) can still be running and keep holding port 8080. Free it and try again:

```bash
./scripts/free-port-8080.sh
cd texasHold/backend && go run .
# or: docker compose up -d
```

## Deploy to GKE (same cluster as TempConv2, own IP)

```bash
export PROJECT_ID=your-gcp-project-id
./scripts/build-and-push.sh $PROJECT_ID
./scripts/deploy-to-gke.sh $PROJECT_ID tempconv2-cluster europe-west1-b
```

Then:

```bash
kubectl get svc frontend -n texashold
# Open http://<EXTERNAL-IP>
```

Texas Hold'em and TempConv2 both run on the same cluster; each has its own namespace and frontend LoadBalancer, so each has its own HTTP address.

## Project layout

```
texasHold/
├── backend/          # Go REST API
│   ├── hand/         # Cards, evaluation, comparison (Norvig-style + Excel test cases)
│   ├── montecarlo/   # Win probability simulation
│   ├── api/          # HTTP handlers, models
│   └── main.go
├── frontend/         # Flutter web (tabs: Evaluate, Compare, Win %)
├── k8s/              # namespace, backend + frontend deployments, services
├── scripts/          # build-and-push.sh, deploy-to-gke.sh
└── README.md
```

## Tests

```bash
cd backend
go test ./hand/... -v
```

Hand comparison tests are derived from the "Texas HoldEm Hand comparison test cases" Excel sheet.
