package montecarlo

import (
	"math/rand"
	"texashold-backend/hand"
)

// WinProbability runs nSims Monte Carlo simulations. Given our 2 hole cards and
// 0/3/4/5 community cards, numPlayers-1 opponents get random hands. Returns
// win fraction (outright wins) and tie fraction (sims where we tie all opponents).
// Equity = winFrac + 0.5*tieFrac.
func WinProbability(hole []hand.Card, community []hand.Card, numPlayers, nSims int) (winFrac, tieFrac float64) {
	if numPlayers < 2 || nSims <= 0 {
		return 0, 0
	}
	if len(hole) != 2 {
		return 0, 0
	}
	wins := 0
	ties := 0
	deck := fullDeck()
	used := make(map[hand.Card]bool)
	for _, c := range hole {
		used[c] = true
	}
	for _, c := range community {
		used[c] = true
	}
	for sim := 0; sim < nSims; sim++ {
		// Shuffle and deal remaining community + opponent hole cards
		remaining := removeUsed(deck, used)
		rand.Shuffle(len(remaining), func(i, j int) { remaining[i], remaining[j] = remaining[j], remaining[i] })
		// Complete community to 5
		commCount := len(community)
		var fullCommunity []hand.Card
		if commCount < 5 {
			fullCommunity = make([]hand.Card, 5)
			copy(fullCommunity, community)
			for i := commCount; i < 5; i++ {
				fullCommunity[i] = remaining[i-commCount]
			}
		} else {
			fullCommunity = community
		}
		idx := 5 - commCount
		// Our best hand
		ourSeven := append(append([]hand.Card(nil), hole...), fullCommunity...)
		ourBest, ourVal := hand.BestHand(ourSeven)
		_ = ourBest
		// Opponents: each gets 2 hole cards from remaining deck
		opponentVals := make([]hand.HandValue, numPlayers-1)
		for o := 0; o < numPlayers-1; o++ {
			o1 := remaining[idx]
			idx++
			o2 := remaining[idx]
			idx++
			oppSeven := append(append([]hand.Card{o1, o2}, fullCommunity...))
			_, oppVal := hand.BestHand(oppSeven)
			opponentVals[o] = oppVal
		}
		// Compare: we need to beat or tie all opponents
		weWin := true
		weTie := true
		for _, ov := range opponentVals {
			cmp := compareHandValues(ourVal, ov)
			if cmp < 0 {
				weWin = false
				weTie = false
				break
			}
			if cmp != 0 {
				weTie = false
			}
		}
		if weWin && weTie {
			ties++
		} else if weWin {
			wins++
		}
	}
	n := float64(nSims)
	return float64(wins) / n, float64(ties) / n
}

// WinProbabilityMulti runs one set of nSims with all players' hole cards fixed.
// In each sim the board is completed from the deck (if needed), then we determine
// winner(s) or tie. Returns per-player win fraction and one tie fraction (same for all).
// Sum of winFracs + tieFrac = 1.0.
func WinProbabilityMulti(holes [][]hand.Card, community []hand.Card, nSims int) (winFracs []float64, tieFrac float64) {
	nPlayers := len(holes)
	if nPlayers < 2 || nSims <= 0 {
		return nil, 0
	}
	for _, h := range holes {
		if len(h) != 2 {
			return nil, 0
		}
	}
	deck := fullDeck()
	used := make(map[hand.Card]bool)
	for _, h := range holes {
		for _, c := range h {
			used[c] = true
		}
	}
	for _, c := range community {
		used[c] = true
	}
	wins := make([]int, nPlayers)
	ties := 0
	for sim := 0; sim < nSims; sim++ {
		remaining := removeUsed(deck, used)
		rand.Shuffle(len(remaining), func(i, j int) { remaining[i], remaining[j] = remaining[j], remaining[i] })
		commCount := len(community)
		var fullCommunity []hand.Card
		if commCount < 5 {
			fullCommunity = make([]hand.Card, 5)
			copy(fullCommunity, community)
			for i := commCount; i < 5; i++ {
				fullCommunity[i] = remaining[i-commCount]
			}
		} else {
			fullCommunity = community
		}
		// Best hand value per player
		vals := make([]hand.HandValue, nPlayers)
		for i := 0; i < nPlayers; i++ {
			seven := append(append([]hand.Card(nil), holes[i]...), fullCommunity...)
			_, vals[i] = hand.BestHand(seven)
		}
		// Find winner(s): who has the best hand?
		bestIdx := 0
		for i := 1; i < nPlayers; i++ {
			if compareHandValues(vals[i], vals[bestIdx]) > 0 {
				bestIdx = i
			}
		}
		nBest := 0
		for i := 0; i < nPlayers; i++ {
			if compareHandValues(vals[i], vals[bestIdx]) == 0 {
				nBest++
			}
		}
		if nBest > 1 {
			ties++
		} else {
			wins[bestIdx]++
		}
	}
	n := float64(nSims)
	out := make([]float64, nPlayers)
	for i := range wins {
		out[i] = float64(wins[i]) / n
	}
	return out, float64(ties) / n
}

func compareHandValues(a, b hand.HandValue) int {
	if a.Type != b.Type {
		if a.Type > b.Type {
			return 1
		}
		return -1
	}
	for i := 0; i < len(a.Values) && i < len(b.Values); i++ {
		if a.Values[i] > b.Values[i] {
			return 1
		}
		if a.Values[i] < b.Values[i] {
			return -1
		}
	}
	return 0
}

func fullDeck() []hand.Card {
	suits := []rune{hand.SuitHeart, hand.SuitSpade, hand.SuitDiamond, hand.SuitClub}
	var deck []hand.Card
	for _, s := range suits {
		for r := hand.Rank2; r <= hand.RankA; r++ {
			deck = append(deck, hand.Card{Suit: s, Rank: r})
		}
	}
	return deck
}

func removeUsed(deck []hand.Card, used map[hand.Card]bool) []hand.Card {
	var out []hand.Card
	for _, c := range deck {
		if !used[c] {
			out = append(out, c)
		}
	}
	return out
}
