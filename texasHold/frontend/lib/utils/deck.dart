import 'dart:math' as math;

/// All 52 cards: HA, H2, ... CK. Suits H S D C, ranks A 2 3 4 5 6 7 8 9 T J Q K.
const List<String> kAllCards = [
  'HA', 'H2', 'H3', 'H4', 'H5', 'H6', 'H7', 'H8', 'H9', 'HT', 'HJ', 'HQ', 'HK',
  'SA', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'S8', 'S9', 'ST', 'SJ', 'SQ', 'SK',
  'DA', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'DT', 'DJ', 'DQ', 'DK',
  'CA', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9', 'CT', 'CJ', 'CQ', 'CK',
];

final Set<String> kValidCards = kAllCards.toSet();

bool isValidCard(String s) {
  return kValidCards.contains(s.trim().toUpperCase());
}

final _rng = math.Random();

/// Returns cards that are still available (not in [used]).
/// [used] should be uppercase trimmed card strings.
List<String> availableDeck(Set<String> used) {
  return kAllCards.where((c) => !used.contains(c)).toList();
}

/// Picks [count] random cards from [available]. Does not modify [available].
List<String> dealRandom(List<String> available, int count) {
  if (count <= 0 || count > available.length) return [];
  final list = List<String>.from(available);
  for (var i = 0; i < count; i++) {
    final j = i + _rng.nextInt(list.length - i);
    final t = list[i];
    list[i] = list[j];
    list[j] = t;
  }
  return list.sublist(0, count);
}
