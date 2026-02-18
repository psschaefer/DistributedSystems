package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"texashold-backend/hand"
	"texashold-backend/montecarlo"
)

func cors(w http.ResponseWriter) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
}

func writeJSON(w http.ResponseWriter, status int, v interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("writeJSON: %v", err)
	}
}

func parseCardsStrings(ss []string) ([]hand.Card, error) {
	var all []hand.Card
	for _, s := range ss {
		s = trimSpace(s)
		if s == "" {
			continue
		}
		c, err := hand.ParseCard(s)
		if err != nil {
			return nil, err
		}
		all = append(all, c)
	}
	return all, nil
}

func trimSpace(s string) string {
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t') {
		s = s[:len(s)-1]
	}
	return s
}

// HandleEvaluate handles POST /api/evaluate
func HandleEvaluate(w http.ResponseWriter, r *http.Request) {
	cors(w)
	if r.Method == "OPTIONS" {
		return
	}
	if r.Method != "POST" {
		writeJSON(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}
	var req EvaluateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Invalid JSON"})
		return
	}
	hole, err := parseCardsStrings(req.HoleCards)
	if err != nil || len(hole) != 2 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Need exactly 2 hole cards"})
		return
	}
	comm, err := parseCardsStrings(req.CommunityCards)
	if err != nil || len(comm) != 5 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Need exactly 5 community cards"})
		return
	}
	all := append(append([]hand.Card(nil), hole...), comm...)
	best, val := hand.BestHand(all)
	bestStrs := make([]string, len(best))
	for i := range best {
		bestStrs[i] = best[i].String()
	}
	winning := hand.WinningCards(best, val, hole)
	winningStrs := make([]string, len(winning))
	for i := range winning {
		winningStrs[i] = winning[i].String()
	}
	writeJSON(w, http.StatusOK, EvaluateResponse{
		BestHand:     bestStrs,
		WinningCards: winningStrs,
		HandType:     val.Type.String(),
		HandValue:    val.Type.String(),
	})
}

// HandleCompare handles POST /api/compare
func HandleCompare(w http.ResponseWriter, r *http.Request) {
	cors(w)
	if r.Method == "OPTIONS" {
		return
	}
	if r.Method != "POST" {
		writeJSON(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}
	var req CompareRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Invalid JSON"})
		return
	}
	h1Hole, err := parseCardsStrings(req.Hand1.HoleCards)
	if err != nil || len(h1Hole) != 2 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Hand1: need exactly 2 hole cards"})
		return
	}
	h1Comm, err := parseCardsStrings(req.Hand1.CommunityCards)
	if err != nil || len(h1Comm) != 5 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Hand1: need exactly 5 community cards"})
		return
	}
	h2Hole, err := parseCardsStrings(req.Hand2.HoleCards)
	if err != nil || len(h2Hole) != 2 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Hand2: need exactly 2 hole cards"})
		return
	}
	h2Comm, err := parseCardsStrings(req.Hand2.CommunityCards)
	if err != nil || len(h2Comm) != 5 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Hand2: need exactly 5 community cards"})
		return
	}
	h1All := append(append([]hand.Card(nil), h1Hole...), h1Comm...)
	h2All := append(append([]hand.Card(nil), h2Hole...), h2Comm...)
	best1, val1 := hand.BestHand(h1All)
	best2, val2 := hand.BestHand(h2All)
	cmp := hand.CompareHands(best1, best2)
	winner := "tie"
	if cmp > 0 {
		winner = "hand1"
	} else if cmp < 0 {
		winner = "hand2"
	}
	best1Strs := make([]string, len(best1))
	for i := range best1 {
		best1Strs[i] = best1[i].String()
	}
	best2Strs := make([]string, len(best2))
	for i := range best2 {
		best2Strs[i] = best2[i].String()
	}
	win1 := hand.WinningCards(best1, val1, h1Hole)
	win2 := hand.WinningCards(best2, val2, h2Hole)
	win1Strs := make([]string, len(win1))
	for i := range win1 {
		win1Strs[i] = win1[i].String()
	}
	win2Strs := make([]string, len(win2))
	for i := range win2 {
		win2Strs[i] = win2[i].String()
	}
	writeJSON(w, http.StatusOK, CompareResponse{
		Hand1Best:       best1Strs,
		Hand1WinningCards: win1Strs,
		Hand1Type:       val1.Type.String(),
		Hand2Best:       best2Strs,
		Hand2WinningCards: win2Strs,
		Hand2Type:       val2.Type.String(),
		Winner:          winner,
	})
}

// HandleWinProbability handles POST /api/win-probability
func HandleWinProbability(w http.ResponseWriter, r *http.Request) {
	cors(w)
	if r.Method == "OPTIONS" {
		return
	}
	if r.Method != "POST" {
		writeJSON(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}
	var req WinProbabilityRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Invalid JSON"})
		return
	}
	hole, err := parseCardsStrings(req.HoleCards)
	if err != nil || len(hole) != 2 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Need exactly 2 hole cards"})
		return
	}
	comm, err := parseCardsStrings(req.CommunityCards)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Invalid community cards"})
		return
	}
	if len(comm) != 0 && len(comm) != 3 && len(comm) != 4 && len(comm) != 5 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Community cards must be 0, 3, 4, or 5"})
		return
	}
	if req.NumPlayers < 2 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "num_players must be at least 2"})
		return
	}
	if req.NumSimulations <= 0 || req.NumSimulations > 500000 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "num_simulations must be 1 to 500000"})
		return
	}
	winProb, tieProb := montecarlo.WinProbability(hole, comm, req.NumPlayers, req.NumSimulations)
	writeJSON(w, http.StatusOK, WinProbabilityResponse{
		WinProbability: winProb,
		TieProbability: tieProb,
		Description:    fmt.Sprintf("Win: %s  Tie: %s", formatPercent(winProb), formatPercent(tieProb)),
	})
}

// HandleWinProbabilityMulti handles POST /api/win-probability-multi
// One simulation with all players' hole cards; win% + tie% sum to 100%.
func HandleWinProbabilityMulti(w http.ResponseWriter, r *http.Request) {
	cors(w)
	if r.Method == "OPTIONS" {
		return
	}
	if r.Method != "POST" {
		writeJSON(w, http.StatusMethodNotAllowed, ErrorResponse{Error: "Method not allowed"})
		return
	}
	var req WinProbabilityMultiRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Invalid JSON"})
		return
	}
	if len(req.Players) < 2 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Need at least 2 players"})
		return
	}
	if req.NumSimulations <= 0 || req.NumSimulations > 500000 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "num_simulations must be 1 to 500000"})
		return
	}
	comm, err := parseCardsStrings(req.CommunityCards)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Invalid community cards"})
		return
	}
	if len(comm) != 0 && len(comm) != 3 && len(comm) != 4 && len(comm) != 5 {
		writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Community cards must be 0, 3, 4, or 5"})
		return
	}
	holes := make([][]hand.Card, len(req.Players))
	for i, p := range req.Players {
		hole, err := parseCardsStrings(p.HoleCards)
		if err != nil || len(hole) != 2 {
			writeJSON(w, http.StatusBadRequest, ErrorResponse{Error: "Each player needs exactly 2 hole cards"})
			return
		}
		holes[i] = hole
	}
	winFracs, tieFrac := montecarlo.WinProbabilityMulti(holes, comm, req.NumSimulations)
	resp := WinProbabilityMultiResponse{Players: make([]WinProbabilityMultiPlayer, len(winFracs))}
	for i := range winFracs {
		resp.Players[i].WinProbability = winFracs[i]
		resp.Players[i].TieProbability = tieFrac
	}
	writeJSON(w, http.StatusOK, resp)
}

func formatPercent(p float64) string {
	return fmt.Sprintf("%.2f%%", p*100)
}
