package api

// EvaluateRequest: 2 hole + 5 community cards.
type EvaluateRequest struct {
	HoleCards     []string `json:"hole_cards"`
	CommunityCards []string `json:"community_cards"`
}

// EvaluateResponse: best hand description and type.
type EvaluateResponse struct {
	BestHand     []string `json:"best_hand"`      // 5 cards (best hand)
	WinningCards []string `json:"winning_cards"` // subset that defines the hand (e.g. 2 for high card, 4 for two pair)
	HandType     string   `json:"hand_type"`
	HandValue    string   `json:"hand_value"`    // same as hand_type for display
}

// CompareRequest: two hands, each 2 hole + 5 community.
type CompareRequest struct {
	Hand1 struct {
		HoleCards     []string `json:"hole_cards"`
		CommunityCards []string `json:"community_cards"`
	} `json:"hand1"`
	Hand2 struct {
		HoleCards     []string `json:"hole_cards"`
		CommunityCards []string `json:"community_cards"`
	} `json:"hand2"`
}

// CompareResponse: best hand for each and winner.
type CompareResponse struct {
	Hand1Best       []string `json:"hand1_best"`
	Hand1WinningCards []string `json:"hand1_winning_cards"`
	Hand1Type       string   `json:"hand1_type"`
	Hand2Best       []string `json:"hand2_best"`
	Hand2WinningCards []string `json:"hand2_winning_cards"`
	Hand2Type       string   `json:"hand2_type"`
	Winner          string   `json:"winner"` // "hand1", "hand2", "tie"
}

// WinProbabilityRequest: 2 hole + 0/3/4/5 community + num_players + num_simulations.
type WinProbabilityRequest struct {
	HoleCards      []string `json:"hole_cards"`
	CommunityCards []string `json:"community_cards"`
	NumPlayers     int      `json:"num_players"`
	NumSimulations int      `json:"num_simulations"`
}

// WinProbabilityResponse: win and tie probability 0.0 to 1.0.
type WinProbabilityResponse struct {
	WinProbability float64 `json:"win_probability"`
	TieProbability float64 `json:"tie_probability"`
	Description    string  `json:"description"`
}

// WinProbabilityMultiRequest: all players' hole cards + community + num_simulations.
// One simulation run; returned win/tie per player sum to 100%.
type WinProbabilityMultiRequest struct {
	Players        []struct{ HoleCards []string `json:"hole_cards"` } `json:"players"`
	CommunityCards []string `json:"community_cards"`
	NumSimulations int     `json:"num_simulations"`
}

// WinProbabilityMultiPlayer is one entry in WinProbabilityMultiResponse.
type WinProbabilityMultiPlayer struct {
	WinProbability float64 `json:"win_probability"`
	TieProbability float64 `json:"tie_probability"`
}

// WinProbabilityMultiResponse: per-player win and tie (tie same for all); sum = 100%.
type WinProbabilityMultiResponse struct {
	Players []WinProbabilityMultiPlayer `json:"players"`
}

// ErrorResponse for 4xx/5xx.
type ErrorResponse struct {
	Error string `json:"error"`
}
