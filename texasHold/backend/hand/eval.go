package hand

import (
	"sort"
)

// Evaluate5 returns the hand type and tiebreaker values for exactly 5 cards.
func Evaluate5(cards []Card) HandValue {
	if len(cards) != 5 {
		return HandValue{Type: HighCard, Values: nil}
	}
	c := make([]Card, 5)
	copy(c, cards)

	// Sort by rank descending (A high).
	sort.Slice(c, func(i, j int) bool { return c[i].Rank > c[j].Rank })

	isFlush := isFlush5(c)
	isStraight, straightHigh := isStraight5(c)

	if isFlush && isStraight {
		if straightHigh == RankA {
			return HandValue{Type: RoyalFlush, Values: nil}
		}
		return HandValue{Type: StraightFlush, Values: []int{straightHigh}}
	}

	ranks := rankCounts(c)

	// Four of a kind
	for r := RankA; r >= Rank2; r-- {
		if ranks[r] == 4 {
			kicker := kickerRank(ranks, r, 1)
			return HandValue{Type: FourOfAKind, Values: []int{r, kicker}}
		}
	}

	// Full house: 3 + 2
	for r3 := RankA; r3 >= Rank2; r3-- {
		if ranks[r3] < 3 {
			continue
		}
		for r2 := RankA; r2 >= Rank2; r2-- {
			if r2 != r3 && ranks[r2] >= 2 {
				return HandValue{Type: FullHouse, Values: []int{r3, r2}}
			}
		}
	}

	if isFlush {
		return HandValue{Type: Flush, Values: sortedRanks(c)}
	}
	if isStraight {
		return HandValue{Type: Straight, Values: []int{straightHigh}}
	}

	// Three of a kind
	for r := RankA; r >= Rank2; r-- {
		if ranks[r] == 3 {
			kickers := kickers(ranks, r, 2)
			return HandValue{Type: ThreeOfAKind, Values: append([]int{r}, kickers...)}
		}
	}

	// Two pairs
	for r1 := RankA; r1 >= Rank2; r1-- {
		if ranks[r1] < 2 {
			continue
		}
		for r2 := RankA; r2 >= Rank2; r2-- {
			if r2 != r1 && ranks[r2] >= 2 {
				k := kickerRank(ranks, r1, r2)
				if r1 > r2 {
					return HandValue{Type: TwoPairs, Values: []int{r1, r2, k}}
				}
				return HandValue{Type: TwoPairs, Values: []int{r2, r1, k}}
			}
		}
	}

	// One pair
	for r := RankA; r >= Rank2; r-- {
		if ranks[r] == 2 {
			kickers := kickers(ranks, r, 3)
			return HandValue{Type: OnePair, Values: append([]int{r}, kickers...)}
		}
	}

	// High card
	return HandValue{Type: HighCard, Values: sortedRanks(c)}
}

func isFlush5(c []Card) bool {
	s := c[0].Suit
	for i := 1; i < 5; i++ {
		if c[i].Suit != s {
			return false
		}
	}
	return true
}

func isStraight5(c []Card) (bool, int) {
	r := make([]int, 5)
	for i := 0; i < 5; i++ {
		r[i] = c[i].Rank
	}
	sort.Slice(r, func(i, j int) bool { return r[i] > r[j] })
	// Normal straight (high card of straight)
	for i := 0; i < 4; i++ {
		if r[i]-r[i+1] != 1 {
			goto wheel
		}
	}
	return true, r[0]
wheel:
	// Wheel: A-2-3-4-5 (Ace low)
	hasA := false
	for i := 0; i < 5; i++ {
		if r[i] == RankA {
			hasA = true
			break
		}
	}
	if !hasA {
		return false, 0
	}
	// Ranks must be A,5,4,3,2 -> 12,3,2,1,0
	seen := make(map[int]bool)
	for i := 0; i < 5; i++ {
		seen[r[i]] = true
	}
	for _, v := range []int{Rank5, Rank4, Rank3, Rank2} {
		if !seen[v] {
			return false, 0
		}
	}
	return true, Rank5 // wheel high card is 5
}

func rankCounts(c []Card) map[int]int {
	m := make(map[int]int)
	for _, card := range c {
		m[card.Rank]++
	}
	return m
}

func kickerRank(ranks map[int]int, exclude ...int) int {
	ex := make(map[int]bool)
	for _, r := range exclude {
		ex[r] = true
	}
	for r := RankA; r >= Rank2; r-- {
		if !ex[r] && ranks[r] > 0 {
			return r
		}
	}
	return -1
}

func kickers(ranks map[int]int, exclude int, n int) []int {
	ex := map[int]bool{exclude: true}
	var out []int
	for r := RankA; r >= Rank2 && len(out) < n; r-- {
		if ex[r] {
			continue
		}
		for k := 0; k < ranks[r] && len(out) < n; k++ {
			out = append(out, r)
		}
	}
	return out
}

func sortedRanks(c []Card) []int {
	r := make([]int, len(c))
	for i := range c {
		r[i] = c[i].Rank
	}
	sort.Slice(r, func(i, j int) bool { return r[i] > r[j] })
	return r
}

// WinningCards returns the subset of cards that define the hand (for display).
// For High Card returns the 2 hole cards; for One Pair 2 cards, Two Pairs 4, etc.
func WinningCards(best []Card, val HandValue, hole []Card) []Card {
	if len(best) != 5 {
		return best
	}
	if val.Type == HighCard && len(hole) == 2 {
		return append([]Card(nil), hole...)
	}
	switch val.Type {
	case OnePair:
		if len(val.Values) >= 1 {
			r := val.Values[0]
			return cardsWithRank(best, r, 2)
		}
	case TwoPairs:
		if len(val.Values) >= 2 {
			out := cardsWithRank(best, val.Values[0], 2)
			out = append(out, cardsWithRank(best, val.Values[1], 2)...)
			return out
		}
	case ThreeOfAKind:
		if len(val.Values) >= 1 {
			return cardsWithRank(best, val.Values[0], 3)
		}
	case FourOfAKind:
		if len(val.Values) >= 1 {
			return cardsWithRank(best, val.Values[0], 4)
		}
	}
	return append([]Card(nil), best...)
}

func cardsWithRank(c []Card, rank int, n int) []Card {
	var out []Card
	for i := range c {
		if c[i].Rank == rank && len(out) < n {
			out = append(out, c[i])
		}
	}
	return out
}
