# Texas Hold'em (REST API + Flutter Web)_
REST API and web UI for Texas Hold'em: hand evaluation, hand comparison, and win probability (Monte Carlo). Same deployment pattern as TempConv: Go backend, Flutter web, Kubernetes with **own external IP** (namespace `texashold`)

# test cases are in hand_test go in backend/hand
# http://34.78.236.112/ for external ip

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
