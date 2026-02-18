package hand

// BestHand returns the best 5-card hand from up to 7 cards (2 hole + 5 community).
// Uses brute force over all C(7,5) combinations.
func BestHand(cards []Card) ([]Card, HandValue) {
	if len(cards) < 5 {
		return nil, HandValue{}
	}
	if len(cards) == 5 {
		v := Evaluate5(cards)
		return append([]Card(nil), cards...), v
	}
	// 6 or 7 cards: try all 5-card subsets
	bestVal := HandValue{Type: HighCard, Values: []int{-1, -1, -1, -1, -1}}
	var bestHand []Card
	combos := choose5(len(cards))
	for _, idx := range combos {
		five := make([]Card, 5)
		for i, j := range idx {
			five[i] = cards[j]
		}
		v := Evaluate5(five)
		if compareHandValues(v, bestVal) > 0 {
			bestVal = v
			bestHand = five
		}
	}
	return bestHand, bestVal
}

// choose5 returns all 5-element subsets of indices 0..n-1.
func choose5(n int) [][]int {
	var out [][]int
	var f func(start int, cur []int)
	f = func(start int, cur []int) {
		if len(cur) == 5 {
			out = append(out, append([]int(nil), cur...))
			return
		}
		for i := start; i < n; i++ {
			f(i+1, append(cur, i))
		}
	}
	f(0, nil)
	return out
}

// CompareHands compares two 5-card hands. Returns: -1 if a<b, 0 if a==b, 1 if a>b.
func CompareHands(a, b []Card) int {
	va := Evaluate5(a)
	vb := Evaluate5(b)
	return compareHandValues(va, vb)
}

func compareHandValues(a, b HandValue) int {
	if a.Type != b.Type {
		if a.Type > b.Type {
			return 1
		}
		return -1
	}
	// Same type: compare tiebreakers
	na, nb := len(a.Values), len(b.Values)
	for i := 0; i < na && i < nb; i++ {
		if a.Values[i] > b.Values[i] {
			return 1
		}
		if a.Values[i] < b.Values[i] {
			return -1
		}
	}
	return 0
}
