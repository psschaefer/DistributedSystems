import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient(this.baseUrl);

  final String baseUrl;

  String get _api => '$baseUrl/api';

  static const _jsonHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, dynamic> _parseJson(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) {
      final status = res.statusCode;
      final hint = status == 415
          ? ' Send Content-Type: application/json.'
          : '';
      throw Exception('Empty response from server ($status).$hint');
    }
    try {
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) throw Exception('Invalid response format');
      return data;
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON from server: ${res.body.length > 80 ? "${res.body.substring(0, 80)}..." : res.body}');
      }
      rethrow;
    }
  }

  Future<EvaluateResult> evaluate(List<String> holeCards, List<String> communityCards) async {
    final res = await http.post(
      Uri.parse('$_api/evaluate'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'hole_cards': holeCards,
        'community_cards': communityCards,
      }),
    );
    final data = _parseJson(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? res.body);
    }
    final winning = data['winning_cards'];
    return EvaluateResult(
      bestHand: List<String>.from(data['best_hand'] as List),
      winningCards: winning != null ? List<String>.from(winning as List) : null,
      handType: data['hand_type'] as String,
    );
  }

  Future<CompareResult> compare({
    required List<String> hand1Hole,
    required List<String> hand1Community,
    required List<String> hand2Hole,
    required List<String> hand2Community,
  }) async {
    final res = await http.post(
      Uri.parse('$_api/compare'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'hand1': {'hole_cards': hand1Hole, 'community_cards': hand1Community},
        'hand2': {'hole_cards': hand2Hole, 'community_cards': hand2Community},
      }),
    );
    final data = _parseJson(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? res.body);
    }
    final w1 = data['hand1_winning_cards'];
    final w2 = data['hand2_winning_cards'];
    return CompareResult(
      hand1Best: List<String>.from(data['hand1_best'] as List),
      hand1WinningCards: w1 != null ? List<String>.from(w1 as List) : null,
      hand1Type: data['hand1_type'] as String,
      hand2Best: List<String>.from(data['hand2_best'] as List),
      hand2WinningCards: w2 != null ? List<String>.from(w2 as List) : null,
      hand2Type: data['hand2_type'] as String,
      winner: data['winner'] as String,
    );
  }

  Future<WinProbabilityResult> winProbability({
    required List<String> holeCards,
    required List<String> communityCards,
    required int numPlayers,
    required int numSimulations,
  }) async {
    final res = await http.post(
      Uri.parse('$_api/win-probability'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'hole_cards': holeCards,
        'community_cards': communityCards,
        'num_players': numPlayers,
        'num_simulations': numSimulations,
      }),
    );
    final data = _parseJson(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? res.body);
    }
    return WinProbabilityResult(
      winProbability: (data['win_probability'] as num).toDouble(),
      tieProbability: (data['tie_probability'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] as String,
    );
  }

  /// One simulation with all players' hole cards; win% and tie% sum to 100%.
  Future<WinProbabilityMultiResult> winProbabilityMulti({
    required List<List<String>> playersHoleCards,
    required List<String> communityCards,
    required int numSimulations,
  }) async {
    final res = await http.post(
      Uri.parse('$_api/win-probability-multi'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'players': playersHoleCards.map((h) => {'hole_cards': h}).toList(),
        'community_cards': communityCards,
        'num_simulations': numSimulations,
      }),
    );
    final data = _parseJson(res);
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? res.body);
    }
    final list = data['players'] as List;
    return WinProbabilityMultiResult(
      players: list.map((p) => WinProbabilityMultiPlayer(
        winProbability: (p['win_probability'] as num).toDouble(),
        tieProbability: (p['tie_probability'] as num).toDouble(),
      )).toList(),
    );
  }
}

class WinProbabilityMultiPlayer {
  WinProbabilityMultiPlayer({required this.winProbability, required this.tieProbability});
  final double winProbability;
  final double tieProbability;
}

class WinProbabilityMultiResult {
  WinProbabilityMultiResult({required this.players});
  final List<WinProbabilityMultiPlayer> players;
}

class EvaluateResult {
  EvaluateResult({required this.bestHand, this.winningCards, required this.handType});
  final List<String> bestHand;
  final List<String>? winningCards;
  final String handType;
}

class CompareResult {
  CompareResult({
    required this.hand1Best,
    this.hand1WinningCards,
    required this.hand1Type,
    required this.hand2Best,
    this.hand2WinningCards,
    required this.hand2Type,
    required this.winner,
  });
  final List<String> hand1Best;
  final List<String>? hand1WinningCards;
  final String hand1Type;
  final List<String> hand2Best;
  final List<String>? hand2WinningCards;
  final String hand2Type;
  final String winner;
}

class WinProbabilityResult {
  WinProbabilityResult({
    required this.winProbability,
    required this.tieProbability,
    required this.description,
  });
  final double winProbability;
  final double tieProbability;
  final String description;
}
