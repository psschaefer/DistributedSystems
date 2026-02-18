package hand

import (
	"testing"
)

func TestParseCard(t *testing.T) {
	c, err := ParseCard("HA")
	if err != nil || c.Suit != SuitHeart || c.Rank != RankA {
		t.Fatalf("ParseCard(HA): %v, %+v", err, c)
	}
	c, err = ParseCard("s7")
	if err != nil || c.Suit != SuitSpade || c.Rank != Rank7 {
		t.Fatalf("ParseCard(s7): %v, %+v", err, c)
	}
}

func TestParseCards(t *testing.T) {
	cards, err := ParseCards("D6 S9 H4 S3 C2")
	if err != nil || len(cards) != 5 {
		t.Fatalf("ParseCards: %v, len=%d", err, len(cards))
	}
}

func TestCompareHands_ExcelCases(t *testing.T) {
	// Excel test cases: hand1, hand2, expected result (hand 1 > hand 2, hand 1 = hand 2, hand 2 > hand 1)
	cases := []struct {
		hand1   string
		hand2   string
		expect  int // -1: hand2 wins, 0: tie, 1: hand1 wins
	}{
		// High Card
		{"CA SK S9 D6 H4", "HA SQ S9 D6 H4", 1},   // SK > SQ
		{"D6 CA H4 SK S9", "HA D6 SQ H4 S9", 1},
		{"CA SK S9 D6 H4", "HA SK S9 D6 H4", 0},   // tie (same 5)
		{"S9 SK CA D6 H4", "H4 HA S9 D6 SK", 0},
		{"DQ S9 C7 D6 H4", "DJ S9 C8 D6 H4", 1},   // DQ > DJ
		{"H4 S9 C7 D6 DQ", "C8 D6 DJ S9 H4", 1},
		// One Pair
		{"DK SK HT C8 C7", "H8 C8 SK HT C7", 1},   // K > 8
		{"DK HT C8 C7 SK", "HT H8 SK C7 C8", 1},
		{"DK SK HT C8 C7", "HK SK HT C8 C7", 0},   // K = K
		{"C8 DK SK HT C7", "HK C8 C7 SK HT", 0},
		{"HA DA ST C9 C6", "HA DA ST C9 H7", -1},  // hand2 wins: 7 > 6
		{"C6 C9 ST DA HA", "HA DA C9 ST H7", -1},
		// Two Pairs
		{"HA SA D6 H6 CK", "CQ DQ D6 H6 SA", 1},   // A > Q
		{"CK D6 H6 HA SA", "CQ DQ SA D6 H6", 1},
		{"HQ DQ D6 H6 SA", "SQ DQ D6 H6 SA", 0},
		{"SA HQ DQ D6 H6", "SQ DQ SA D6 H6", 0},
		{"HQ DQ C6 D6 SA", "CA SA HK CK DQ", -1},  // hand2: A > Q
		{"C6 D6 HQ DQ SA", "DQ HK CK CA SA", -1},
		// Three of a Kind
		{"HJ SJ SJ SA C8", "D3 H3 C3 SA SJ", 1},   // J > 3
		{"SA C8 HJ SJ SJ", "D3 SA SJ H3 C3", 1},
		{"D3 H3 C3 SA SJ", "D3 H3 S3 SA SJ", 0},
		{"D3 SA H3 SJ C3", "SA D3 H3 S3 SJ", 0},
		{"HA SA DA HT S5", "HA SA DA SK HT", -1},  // K > T
		{"HA SA HT S5 DA", "SK HA SA DA HT", -1},
		// Straight
		{"H3 S4 C5 S6 D7", "H2 H3 S4 C5 S6", 1},   // 7 > 6
		{"S6 D7 H3 S4 C5", "H3 H2 C5 S4 S6", 1},
		{"H3 S4 C5 S6 D7", "H3 S4 C5 S6 H7", 0},
		{"C5 S6 D7 H3 S4", "H3 S6 H7 S4 C5", 0},
		{"HA H2 H3 S4 C5", "H2 H3 S4 C5 H6", -1},  // 6 > 5
		{"H2 H3 S4 C5 HA", "H3 S4 C5 H6 H2", -1},
		// Flush
		{"D3 D6 DT DK DA", "D3 D6 DT D2 DQ", 1},   // A > Q
		{"D3 D6 DA DT DK", "D3 DQ D6 DT D2", 1},
		{"D3 D6 DT DJ DK", "D3 D6 DT DJ DK", 0},
		{"D6 DT DJ DK D3", "D3 DK D6 DT DJ", 0},
		{"D3 D6 DT D2 D5", "D3 D6 DT DJ DA", -1},
		{"D2 D5 D3 D6 DT", "D3 DJ DA D6 DT", -1},
		// Full House
		{"HQ SQ DQ HT DT", "HQ SQ HT DT CT", 1},    // 3Q > 3T
		{"HQ HT DT SQ DQ", "SQ HT HQ DT CT", 1},
		{"HA SA DQ HQ SQ", "DA SA CQ HQ SQ", 0},
		{"DQ HQ SQ HA SA", "DA HQ SQ SA CQ", 0},
		{"HQ SQ HT DT ST", "HQ SQ CQ HT DT", -1},  // 3Q > 3T (hand2)
		{"HT DT ST HQ SQ", "HQ HT SQ DT CQ", -1},
		// Four of a Kind
		{"HT ST CT DT HA", "HT ST CT DT HK", 1},   // A > K
		{"HT HA ST CT DT", "ST CT DT HK HT", 1},
		{"S5 D5 C5 H5 HA", "S5 D5 C5 H5 HA", 0},
		{"HA S5 D5 C5 H5", "S5 D5 C5 H5 HA", 0},
		{"HT ST CT DT S8", "HT ST CT DT HK", -1},
		{"CT DT S8 HT ST", "CT DT HK HT ST", -1},
		// Straight Flush
		{"H3 H4 H5 H6 H7", "H2 H3 H4 H5 H6", 1},   // 7 > 6
		{"H3 H4 H5 H7 H6", "H4 H5 H2 H3 H6", 1},
		{"H3 H4 H5 H6 H7", "H3 H4 H5 H6 H7", 0},
		{"H7 H6 H4 H3 H5", "H3 H7 H4 H5 H6", 0},
		{"S6 S7 S8 S9 ST", "S7 S8 S9 ST SJ", -1}, // J > T
		{"S6 ST S7 S8 S9", "S7 S8 SJ S9 ST", -1},
		// Royal Flush
		{"DT DJ DQ DK DA", "DT DJ DQ DK DA", 0},
	}
	for i, tc := range cases {
		h1, err := ParseCards(tc.hand1)
		if err != nil {
			t.Fatalf("case %d hand1 %q: %v", i, tc.hand1, err)
		}
		h2, err := ParseCards(tc.hand2)
		if err != nil {
			t.Fatalf("case %d hand2 %q: %v", i, tc.hand2, err)
		}
		if len(h1) != 5 || len(h2) != 5 {
			t.Fatalf("case %d: need 5 cards each, got %d and %d", i, len(h1), len(h2))
		}
		got := CompareHands(h1, h2)
		if got != tc.expect {
			t.Errorf("case %d: %q vs %q: got %d, want %d", i, tc.hand1, tc.hand2, got, tc.expect)
		}
	}
}

func TestBestHand(t *testing.T) {
	// 2 hole + 5 community -> best 5
	hole, _ := ParseCards("SK CA")
	comm, _ := ParseCards("D6 S9 H4 S3 C2")
	all := append(hole, comm...)
	best, val := BestHand(all)
	if len(best) != 5 {
		t.Fatalf("BestHand: want 5 cards, got %d", len(best))
	}
	if val.Type != HighCard {
		t.Errorf("expected High Card, got %s", val.Type.String())
	}
}

// TestExcelEdgeCases tests edge cases from "Texas HoldEm Hand comparison test cases" Excel sheet.
func TestExcelEdgeCases(t *testing.T) {
	t.Run("permutation_tie", func(t *testing.T) {
		// "hands are only permutations of previous line" -> same 5 cards, different order = tie
		h1, _ := ParseCards("SA HQ DQ D6 H6")
		h2, _ := ParseCards("SQ DQ SA D6 H6")
		if CompareHands(h1, h2) != 0 {
			t.Errorf("permutation of same 5 cards should tie: got %d", CompareHands(h1, h2))
		}
	})

	t.Run("four_of_a_kind_on_board_player_cards_irrelevant", func(t *testing.T) {
		// Board has quads (four 5s + Ace); different hole cards -> same best hand -> tie
		board, _ := ParseCards("S5 D5 C5 H5 HA")
		p1Hole, _ := ParseCards("C2 C3")
		p2Hole, _ := ParseCards("D2 D3")
		p1All := append(append([]Card(nil), p1Hole...), board...)
		p2All := append(append([]Card(nil), p2Hole...), board...)
		best1, _ := BestHand(p1All)
		best2, _ := BestHand(p2All)
		if cmp := CompareHands(best1, best2); cmp != 0 {
			t.Errorf("four of a kind on board: hole cards irrelevant, expect tie; got %d", cmp)
		}
	})

	t.Run("royal_flush_on_board_both_tie", func(t *testing.T) {
		// "two players can only have a Royal Flush if the Royal Flush is in the community cards"
		board, _ := ParseCards("DT DJ DQ DK DA")
		p1Hole, _ := ParseCards("C2 C3")
		p2Hole, _ := ParseCards("H2 H3")
		p1All := append(append([]Card(nil), p1Hole...), board...)
		p2All := append(append([]Card(nil), p2Hole...), board...)
		best1, v1 := BestHand(p1All)
		best2, v2 := BestHand(p2All)
		if v1.Type != RoyalFlush || v2.Type != RoyalFlush {
			t.Fatalf("expected both Royal Flush; got %s, %s", v1.Type, v2.Type)
		}
		if cmp := CompareHands(best1, best2); cmp != 0 {
			t.Errorf("royal flush on board: expect tie; got %d", cmp)
		}
	})

	t.Run("best_hand_on_board_player_cards_irrelevant", func(t *testing.T) {
		// "the specific player cards are in this case irrelevant for the comparison"
		// Board is a straight; both players' best 5 = board -> tie
		board, _ := ParseCards("H3 S4 C5 S6 D7")
		p1Hole, _ := ParseCards("C2 C8")
		p2Hole, _ := ParseCards("D2 D8")
		p1All := append(append([]Card(nil), p1Hole...), board...)
		p2All := append(append([]Card(nil), p2Hole...), board...)
		best1, v1 := BestHand(p1All)
		best2, v2 := BestHand(p2All)
		if v1.Type != Straight || v2.Type != Straight {
			t.Fatalf("expected both Straight; got %s, %s", v1.Type, v2.Type)
		}
		if cmp := CompareHands(best1, best2); cmp != 0 {
			t.Errorf("best hand on board: expect tie; got %d", cmp)
		}
	})
}
