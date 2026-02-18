package hand

// HandType is the poker hand rank (higher = better).
const (
	HighCard HandType = iota
	OnePair
	TwoPairs
	ThreeOfAKind
	Straight
	Flush
	FullHouse
	FourOfAKind
	StraightFlush
	RoyalFlush
)

// HandType value for comparison.
type HandType int

func (h HandType) String() string {
	switch h {
	case HighCard:
		return "High Card"
	case OnePair:
		return "One Pair"
	case TwoPairs:
		return "Two Pairs"
	case ThreeOfAKind:
		return "Three of a Kind"
	case Straight:
		return "Straight"
	case Flush:
		return "Flush"
	case FullHouse:
		return "Full House"
	case FourOfAKind:
		return "Four of a Kind"
	case StraightFlush:
		return "Straight Flush"
	case RoyalFlush:
		return "Royal Flush"
	default:
		return "Unknown"
	}
}

// HandValue holds the hand type and tiebreaker values (for comparing same type).
// Tiebreakers: e.g. for One Pair, [pair_rank, kicker1, kicker2, kicker3].
type HandValue struct {
	Type   HandType
	Values []int // tiebreaker ranks (higher first)
}
