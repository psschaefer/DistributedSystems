package hand

import (
	"fmt"
	"strings"
	"unicode"
)

// Suit and Rank for a card. Card = 2 chars: suit + rank (e.g. HA, S7, CT).
const (
	SuitHeart   = 'H'
	SuitSpade   = 'S'
	SuitDiamond = 'D'
	SuitClub    = 'C'
)

// Rank values: 2=0 .. K=11, A=12 (Ace high). For straights, A can be low (wheel).
const (
	Rank2 int = iota
	Rank3
	Rank4
	Rank5
	Rank6
	Rank7
	Rank8
	Rank9
	RankT
	RankJ
	RankQ
	RankK
	RankA
)

// Card is a single card with suit and rank.
type Card struct {
	Suit rune // H, S, D, C
	Rank int  // 0-12
}

// String returns 2-char representation e.g. "HA", "S7".
func (c Card) String() string {
	suit := string(c.Suit)
	rank := rankToChar(c.Rank)
	return suit + rank
}

func rankToChar(r int) string {
	if r == RankT {
		return "T"
	}
	if r == RankJ {
		return "J"
	}
	if r == RankQ {
		return "Q"
	}
	if r == RankK {
		return "K"
	}
	if r == RankA {
		return "A"
	}
	return fmt.Sprintf("%d", r+2)
}

// ParseCard parses a 2-char string (e.g. "HA", "S7") into a Card. Returns error if invalid.
func ParseCard(s string) (Card, error) {
	s = strings.TrimSpace(s)
	if len(s) < 2 {
		return Card{}, fmt.Errorf("card too short: %q", s)
	}
	s = strings.ToUpper(s)
	var suit rune
	for _, r := range s[:1] {
		suit = r
		break
	}
	rankChar := s[1:2]
	var rank int
	switch strings.ToUpper(rankChar) {
	case "2":
		rank = Rank2
	case "3":
		rank = Rank3
	case "4":
		rank = Rank4
	case "5":
		rank = Rank5
	case "6":
		rank = Rank6
	case "7":
		rank = Rank7
	case "8":
		rank = Rank8
	case "9":
		rank = Rank9
	case "T":
		rank = RankT
	case "J":
		rank = RankJ
	case "Q":
		rank = RankQ
	case "K":
		rank = RankK
	case "A":
		rank = RankA
	default:
		return Card{}, fmt.Errorf("invalid rank: %q", rankChar)
	}
	switch suit {
	case SuitHeart, SuitSpade, SuitDiamond, SuitClub:
		return Card{Suit: suit, Rank: rank}, nil
	default:
		return Card{}, fmt.Errorf("invalid suit: %q", string(suit))
	}
}

// ParseCards parses a space-separated string of cards (e.g. "HA S7 D2"). Normalizes \xa0 to space.
func ParseCards(s string) ([]Card, error) {
	s = strings.ReplaceAll(s, "\u00a0", " ")
	parts := strings.Fields(s)
	cards := make([]Card, 0, len(parts))
	for _, p := range parts {
		c, err := ParseCard(p)
		if err != nil {
			return nil, err
		}
		cards = append(cards, c)
	}
	return cards, nil
}

// normalizeSpace normalizes unicode spaces to ASCII space for parsing.
func normalizeSpace(s string) string {
	var b strings.Builder
	for _, r := range s {
		if unicode.IsSpace(r) {
			b.WriteRune(' ')
		} else {
			b.WriteRune(r)
		}
	}
	return strings.Join(strings.Fields(b.String()), " ")
}
