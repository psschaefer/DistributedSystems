import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../utils/deck.dart';
import '../widgets/card_display.dart';
import '../widgets/poker_table.dart';

// In debug: backend often on 8080; if 8080 is in use, run backend with PORT=8081 and use 8081 here
String get _apiBaseUrl => kDebugMode ? 'http://localhost:8080' : '';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiClient _api;
  String get _baseUrl => _apiBaseUrl;

  static const int _seatCount = 10;

  late List<List<TextEditingController>?> _seatHoleCards;
  late List<int?> _seatPlayerNumbers; // P1..P10 by add order
  late List<TextEditingController> _communityCards;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _api = ApiClient(_baseUrl);
    _seatHoleCards = List.filled(_seatCount, null);
    _seatPlayerNumbers = List.filled(_seatCount, null);
    _communityCards = List.generate(5, (_) => TextEditingController());
  }

  int _nextPlayerNumber() {
    final used = _seatPlayerNumbers.whereType<int>().toSet();
    for (var k = 1; k <= 10; k++) {
      if (!used.contains(k)) return k;
    }
    return 10;
  }

  void _addSeat(int i) {
    if (_seatHoleCards[i] != null) return;
    setState(() {
      _seatHoleCards[i] = [TextEditingController(), TextEditingController()];
      _seatPlayerNumbers[i] = _nextPlayerNumber();
    });
  }

  void _removeSeat(int i) {
    final slot = _seatHoleCards[i];
    if (slot == null) return;
    for (final c in slot) c.dispose();
    setState(() {
      _seatHoleCards[i] = null;
      _seatPlayerNumbers[i] = null;
    });
  }

  void _removeAllPlayers() {
    setState(() {
      for (var i = 0; i < _seatCount; i++) {
        final slot = _seatHoleCards[i];
        if (slot != null) {
          for (final c in slot) c.dispose();
          _seatHoleCards[i] = null;
          _seatPlayerNumbers[i] = null;
        }
      }
    });
  }

  Set<String> _getUsedCards() {
    final used = <String>{};
    for (final slot in _seatHoleCards) {
      if (slot != null) {
        for (final c in slot) {
          final s = c.text.trim().toUpperCase();
          if (s.isNotEmpty) used.add(s);
        }
      }
    }
    for (final c in _communityCards) {
      final s = c.text.trim().toUpperCase();
      if (s.isNotEmpty) used.add(s);
    }
    return used;
  }

  Map<String, int> _getUsedCardsCount() {
    final count = <String, int>{};
    for (final slot in _seatHoleCards) {
      if (slot != null) {
        for (final c in slot) {
          final s = c.text.trim().toUpperCase();
          if (s.isNotEmpty) count[s] = (count[s] ?? 0) + 1;
        }
      }
    }
    for (final c in _communityCards) {
      final s = c.text.trim().toUpperCase();
      if (s.isNotEmpty) count[s] = (count[s] ?? 0) + 1;
    }
    return count;
  }

  bool _hasDuplicateCards(Map<String, int> usedCount) {
    return usedCount.values.any((v) => v > 1);
  }

  List<String> _getInvalidCards(Map<String, int> usedCount) {
    return usedCount.keys.where((s) => !isValidCard(s)).toList();
  }

  void _newGame() {
    setState(() {
      for (final slot in _seatHoleCards) {
        if (slot != null) {
          for (final c in slot) c.text = '';
        }
      }
      for (final c in _communityCards) c.text = '';
    });
  }

  void _dealFlop() {
    final available = availableDeck(_getUsedCards());
    if (available.length < 3) return;
    final dealt = dealRandom(available, 3);
    setState(() {
      for (var i = 0; i < 3; i++) _communityCards[i].text = dealt[i];
    });
  }

  void _dealTurn() {
    final available = availableDeck(_getUsedCards());
    if (available.isEmpty) return;
    final dealt = dealRandom(available, 1);
    setState(() => _communityCards[3].text = dealt[0]);
  }

  void _dealRiver() {
    final available = availableDeck(_getUsedCards());
    if (available.isEmpty) return;
    final dealt = dealRandom(available, 1);
    setState(() => _communityCards[4].text = dealt[0]);
  }

  void _clearFlop() {
    setState(() {
      for (var i = 0; i < 3; i++) _communityCards[i].text = '';
    });
  }

  void _clearTurn() {
    setState(() => _communityCards[3].text = '');
  }

  void _clearRiver() {
    setState(() => _communityCards[4].text = '');
  }

  void _dealHoleForSeat(int i) {
    final slot = _seatHoleCards[i];
    if (slot == null) return;
    final available = availableDeck(_getUsedCards());
    if (available.length < 2) return;
    final dealt = dealRandom(available, 2);
    setState(() {
      slot[0].text = dealt[0];
      slot[1].text = dealt[1];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final slot in _seatHoleCards) {
      if (slot != null) for (final c in slot) c.dispose();
    }
    for (final c in _communityCards) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usedCount = _getUsedCardsCount();
    final hasDuplicate = _hasDuplicateCards(usedCount);
    final invalidCards = _getInvalidCards(usedCount);
    final canCalculate = !hasDuplicate && invalidCards.isEmpty;
    final blockMessage = hasDuplicate
        ? 'Duplicate cards on table. Fix before calculating.'
        : (invalidCards.isNotEmpty
            ? 'Invalid card(s): ${invalidCards.join(", ")}. Use H/S/D/C + A,2-9,T,J,Q,K.'
            : null);
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surfaceContainerLowest;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Texas Hold'em"),
        backgroundColor: surfaceColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 2,
                  color: surfaceColor,
                  child: _LeftPanel(
                    seatHoleCards: _seatHoleCards,
                    seatPlayerNumbers: _seatPlayerNumbers,
                    onNewGame: _newGame,
                    onRemoveAllPlayers: _removeAllPlayers,
                    onDealFlop: _dealFlop,
                    onDealTurn: _dealTurn,
                    onDealRiver: _dealRiver,
                    onClearFlop: _clearFlop,
                    onClearTurn: _clearTurn,
                    onClearRiver: _clearRiver,
                    onDealHoleForSeat: _dealHoleForSeat,
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRect(
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: PokerTable(
                            seatHoleCards: _seatHoleCards,
                            seatPlayerNumbers: _seatPlayerNumbers,
                            communityCards: _communityCards,
                            onAddSeat: _addSeat,
                            onRemoveSeat: _removeSeat,
                            onCardChanged: () => setState(() {}),
                            usedCardsCount: usedCount,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 440,
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Evaluate'),
                    Tab(text: 'Compare'),
                    Tab(text: 'Win %'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _EvaluateTab(api: _api, seatHoleCards: _seatHoleCards, seatPlayerNumbers: _seatPlayerNumbers, communityCards: _communityCards, canCalculate: canCalculate, blockMessage: blockMessage),
                      _CompareTab(api: _api, seatHoleCards: _seatHoleCards, seatPlayerNumbers: _seatPlayerNumbers, communityCards: _communityCards, canCalculate: canCalculate, blockMessage: blockMessage),
                      _WinProbabilityTab(api: _api, seatHoleCards: _seatHoleCards, seatPlayerNumbers: _seatPlayerNumbers, communityCards: _communityCards, canCalculate: canCalculate, blockMessage: blockMessage),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One row: [refresh] Label [minus], same look as FilledButton.tonal.
class _BoardActionRow extends StatelessWidget {
  const _BoardActionRow({
    required this.label,
    required this.onRefresh,
    required this.onClear,
  });

  final String label;
  final VoidCallback onRefresh;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            IconButton(
              onPressed: onClear,
              icon: const Icon(Icons.remove, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20))),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              ),
            ),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.add, size: 18),
              style: IconButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.seatHoleCards,
    required this.seatPlayerNumbers,
    required this.onNewGame,
    required this.onRemoveAllPlayers,
    required this.onDealFlop,
    required this.onDealTurn,
    required this.onDealRiver,
    required this.onClearFlop,
    required this.onClearTurn,
    required this.onClearRiver,
    required this.onDealHoleForSeat,
  });

  final List<List<TextEditingController>?> seatHoleCards;
  final List<int?> seatPlayerNumbers;
  final VoidCallback onNewGame;
  final VoidCallback onRemoveAllPlayers;
  final VoidCallback onDealFlop;
  final VoidCallback onDealTurn;
  final VoidCallback onDealRiver;
  final VoidCallback onClearFlop;
  final VoidCallback onClearTurn;
  final VoidCallback onClearRiver;
  final ValueChanged<int> onDealHoleForSeat;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onNewGame,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('New game'),
            ),
            const SizedBox(height: 6),
            FilledButton.tonalIcon(
              onPressed: seatHoleCards.any((s) => s != null) ? onRemoveAllPlayers : null,
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('Remove all players'),
            ),
            const SizedBox(height: 12),
            Text(
              'Type in cards correctly or deal automatically:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Text('Board', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            _BoardActionRow(
              label: 'Flop (3)',
              onRefresh: onDealFlop,
              onClear: onClearFlop,
            ),
            const SizedBox(height: 4),
            _BoardActionRow(
              label: 'Turn (1)',
              onRefresh: onDealTurn,
              onClear: onClearTurn,
            ),
            const SizedBox(height: 4),
            _BoardActionRow(
              label: 'River (1)',
              onRefresh: onDealRiver,
              onClear: onClearRiver,
            ),
            const SizedBox(height: 16),
            Text('Deal hole cards', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            ...() {
              final entries = <(int seatIndex, int playerNum)>[];
              for (var i = 0; i < 10; i++) {
                if (seatHoleCards[i] != null) {
                  final p = seatPlayerNumbers[i];
                  if (p != null) entries.add((i, p));
                }
              }
              entries.sort((a, b) => a.$2.compareTo(b.$2));
              return entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FilledButton.tonal(
                  onPressed: () => onDealHoleForSeat(e.$1),
                  child: Text('P${e.$2}'),
                ),
              )).toList();
            }(),
          ],
        ),
      ),
    );
  }
}

/// Choose a player and evaluate their best hand with the board.
class _EvaluateTab extends StatefulWidget {
  const _EvaluateTab({
    required this.api,
    required this.seatHoleCards,
    required this.seatPlayerNumbers,
    required this.communityCards,
    required this.canCalculate,
    required this.blockMessage,
  });

  final ApiClient api;
  final List<List<TextEditingController>?> seatHoleCards;
  final List<int?> seatPlayerNumbers;
  final List<TextEditingController> communityCards;
  final bool canCalculate;
  final String? blockMessage;

  @override
  State<_EvaluateTab> createState() => _EvaluateTabState();
}

class _EvaluateTabState extends State<_EvaluateTab> {
  int? _selectedPlayerNum;
  String? _handType;
  List<String>? _bestHand;
  String? _error;
  bool _loading = false;

  List<({int playerNum, List<String> hole})> _activePlayers() {
    final list = <({int playerNum, List<String> hole})>[];
    for (var i = 0; i < widget.seatHoleCards.length; i++) {
      final slot = widget.seatHoleCards[i];
      final p = widget.seatPlayerNumbers[i];
      if (slot != null && p != null) {
        final a = slot[0].text.trim().toUpperCase();
        final b = slot[1].text.trim().toUpperCase();
        if (a.isNotEmpty && b.isNotEmpty) list.add((playerNum: p, hole: [a, b]));
      }
    }
    return list;
  }

  List<String> _holeForPlayer(int playerNum) {
    for (final p in _activePlayers()) {
      if (p.playerNum == playerNum) return p.hole;
    }
    return [];
  }

  List<String> _communityList() {
    return widget.communityCards
        .map((c) => c.text.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _evaluate() async {
    final players = _activePlayers();
    final effectiveSelected = _selectedPlayerNum ?? (players.isNotEmpty ? players.first.playerNum : null);
    if (!widget.canCalculate || effectiveSelected == null) return;
    setState(() {
      _error = null;
      _handType = null;
      _bestHand = null;
      _loading = true;
    });
    try {
      final hole = _holeForPlayer(effectiveSelected);
      final comm = _communityList();
      if (hole.length != 2 || comm.length != 5) {
        setState(() {
          _error = 'Selected player needs 2 hole cards and board must have 5 community cards.';
          _loading = false;
        });
        return;
      }
      final r = await widget.api.evaluate(hole, comm);
      setState(() {
        _handType = r.handType;
        _bestHand = r.winningCards ?? r.bestHand;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = _activePlayers();
    final effectiveSelected = _selectedPlayerNum ?? (players.isNotEmpty ? players.first.playerNum : null);
    final comm = _communityList();
    final canRun = widget.canCalculate && effectiveSelected != null && _holeForPlayer(effectiveSelected).length == 2 && comm.length == 5;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Choose player hand to evaluate'),
          if (widget.blockMessage != null) ...[
            const SizedBox(height: 6),
            Text(widget.blockMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            value: effectiveSelected,
            decoration: const InputDecoration(
              labelText: 'Player',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: players.map((p) => DropdownMenuItem<int>(value: p.playerNum, child: Text('P${p.playerNum}'))).toList(),
            onChanged: players.isEmpty ? null : (v) => setState(() => _selectedPlayerNum = v),
          ),
          const SizedBox(height: 12),
          Tooltip(
            message: !canRun && !_loading
                ? (widget.blockMessage ?? (players.isEmpty ? 'Add at least one player with 2 hole cards on the table.' : 'Fill all 5 community cards.'))
                : '',
            child: FilledButton(
              onPressed: (_loading || !canRun) ? null : _evaluate,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Evaluate'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_handType != null && _bestHand != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Best hand: $_handType', style: Theme.of(context).textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    CardDisplayRow(cards: _bestHand!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Winner callout with shooting-star style box (between board and players in Compare).
class _WinnerBox extends StatelessWidget {
  const _WinnerBox({required this.winnerLabel, required this.theme});

  final String winnerLabel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.6),
            theme.colorScheme.tertiaryContainer.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary, width: 2),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 0),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: 0, top: -2, child: Text('✦', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary.withOpacity(0.9)))),
          Positioned(right: 0, top: -2, child: Text('✦', style: TextStyle(fontSize: 14, color: theme.colorScheme.primary.withOpacity(0.9)))),
          Positioned(left: 4, bottom: -2, child: Text('☆', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary.withOpacity(0.7)))),
          Positioned(right: 4, bottom: -2, child: Text('☆', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary.withOpacity(0.7)))),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('★ ', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary)),
                Text(winnerLabel, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                Text(' ★', style: TextStyle(fontSize: 16, color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// All active players + board → each hand (best 5 cards) and overall winner.
class _CompareTab extends StatefulWidget {
  const _CompareTab({
    required this.api,
    required this.seatHoleCards,
    required this.seatPlayerNumbers,
    required this.communityCards,
    required this.canCalculate,
    required this.blockMessage,
  });

  final ApiClient api;
  final List<List<TextEditingController>?> seatHoleCards;
  final List<int?> seatPlayerNumbers;
  final List<TextEditingController> communityCards;
  final bool canCalculate;
  final String? blockMessage;

  @override
  State<_CompareTab> createState() => _CompareTabState();
}

class _CompareResult {
  _CompareResult({required this.board, required this.players, required this.winnerIndices});
  final List<String> board;
  final List<({int playerNum, String handType, List<String> winningCards})> players;
  /// Indices of players with the best hand (one winner or multiple for tie).
  final List<int> winnerIndices;
}

class _CompareTabState extends State<_CompareTab> {
  _CompareResult? _result;
  String? _error;
  bool _loading = false;

  List<({int playerNum, List<String> hole})> _activePlayers() {
    final list = <({int playerNum, List<String> hole})>[];
    for (var i = 0; i < widget.seatHoleCards.length; i++) {
      final slot = widget.seatHoleCards[i];
      final p = widget.seatPlayerNumbers[i];
      if (slot != null && p != null) {
        final a = slot[0].text.trim().toUpperCase();
        final b = slot[1].text.trim().toUpperCase();
        if (a.isNotEmpty && b.isNotEmpty) list.add((playerNum: p, hole: [a, b]));
      }
    }
    return list;
  }

  List<String> _communityList() {
    return widget.communityCards
        .map((c) => c.text.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _compare() async {
    if (!widget.canCalculate) return;
    setState(() {
      _error = null;
      _result = null;
      _loading = true;
    });
    try {
      final players = _activePlayers();
      final comm = _communityList();
      if (players.length < 2 || comm.length != 5) {
        setState(() {
          _error = 'Add at least 2 players with hole cards and fill all 5 community cards.';
          _loading = false;
        });
        return;
      }
      // Evaluate each player → hand type + best 5 cards (only cards that matter)
      final evaluated = <({int playerNum, String handType, List<String> winningCards})>[];
      for (final p in players) {
        final r = await widget.api.evaluate(p.hole, comm);
        evaluated.add((playerNum: p.playerNum, handType: r.handType, winningCards: r.winningCards ?? r.bestHand));
      }
      // Find winner: compare all pairwise (current winner vs next)
      var winnerIdx = 0;
      for (var i = 1; i < players.length; i++) {
        final r = await widget.api.compare(
          hand1Hole: players[winnerIdx].hole,
          hand1Community: comm,
          hand2Hole: players[i].hole,
          hand2Community: comm,
        );
        if (r.winner == 'hand2') winnerIdx = i;
      }
      // Collect all players who tie with the current winner
      final winnerIndices = <int>[winnerIdx];
      for (var i = 0; i < players.length; i++) {
        if (i == winnerIdx) continue;
        final r = await widget.api.compare(
          hand1Hole: players[winnerIdx].hole,
          hand1Community: comm,
          hand2Hole: players[i].hole,
          hand2Community: comm,
        );
        if (r.winner == 'tie') winnerIndices.add(i);
      }
      setState(() {
        _result = _CompareResult(board: comm, players: evaluated, winnerIndices: winnerIndices);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = _activePlayers();
    final canRun = widget.canCalculate && players.length >= 2 && _communityList().length == 5;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Compare the hands of all active players. Best hand per player and overall winner below.'),
          if (widget.blockMessage != null) ...[
            const SizedBox(height: 6),
            Text(widget.blockMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          Tooltip(
            message: !canRun && !_loading
                ? (widget.blockMessage ?? (players.length < 2 ? 'Add at least 2 players with hole cards and fill all 5 community cards.' : 'Fill all 5 community cards.'))
                : '',
            child: FilledButton(
              onPressed: (_loading || !canRun) ? null : _compare,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Compare'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text('Board', style: theme.textTheme.titleSmall),
            const SizedBox(height: 6),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CardDisplayRow(cards: _result!.board),
              ),
            ),
            const SizedBox(height: 14),
            _WinnerBox(
              winnerLabel: _result!.winnerIndices.length > 1
                  ? 'Tie: ${_result!.winnerIndices.map((i) => 'P${_result!.players[i].playerNum}').join(', ')}'
                  : 'Winner: P${_result!.players[_result!.winnerIndices.first].playerNum}',
              theme: theme,
            ),
            const SizedBox(height: 14),
            ...List.generate(_result!.players.length, (i) {
              final p = _result!.players[i];
              final isWinner = _result!.winnerIndices.contains(i);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isWinner ? theme.colorScheme.primary : theme.dividerColor,
                      width: isWinner ? 3 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('P${p.playerNum}  ·  ${p.handType}', style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        CardDisplayRow(cards: p.winningCards),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Monte Carlo win probability for each active player (split by player).
class _WinProbabilityTab extends StatefulWidget {
  const _WinProbabilityTab({
    required this.api,
    required this.seatHoleCards,
    required this.seatPlayerNumbers,
    required this.communityCards,
    required this.canCalculate,
    required this.blockMessage,
  });

  final ApiClient api;
  final List<List<TextEditingController>?> seatHoleCards;
  final List<int?> seatPlayerNumbers;
  final List<TextEditingController> communityCards;
  final bool canCalculate;
  final String? blockMessage;

  @override
  State<_WinProbabilityTab> createState() => _WinProbabilityTabState();
}

class _WinProbabilityResult {
  _WinProbabilityResult({required this.board, required this.players});
  final List<String> board;
  /// winPct, tiePct (sum across all players = 100%)
  final List<({int playerNum, String winPct, String tiePct})> players;
}

class _WinProbabilityTabState extends State<_WinProbabilityTab> {
  final TextEditingController _numSims = TextEditingController(text: '10000');
  _WinProbabilityResult? _result;
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _numSims.dispose();
    super.dispose();
  }

  List<({int playerNum, List<String> hole})> _activePlayers() {
    final list = <({int playerNum, List<String> hole})>[];
    for (var i = 0; i < widget.seatHoleCards.length; i++) {
      final slot = widget.seatHoleCards[i];
      final p = widget.seatPlayerNumbers[i];
      if (slot != null && p != null) {
        final a = slot[0].text.trim().toUpperCase();
        final b = slot[1].text.trim().toUpperCase();
        if (a.isNotEmpty && b.isNotEmpty) {
          list.add((playerNum: p, hole: [a, b]));
        }
      }
    }
    return list;
  }

  List<String> _communityList() {
    return widget.communityCards
        .map((c) => c.text.trim().toUpperCase())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _run() async {
    if (!widget.canCalculate) return;
    setState(() {
      _error = null;
      _result = null;
      _loading = true;
    });
    try {
      final players = _activePlayers();
      final comm = _communityList();
      if (players.length < 2) {
        setState(() {
          _error = 'Add at least 2 players with hole cards on the table.';
          _loading = false;
        });
        return;
      }

      // With 5 board cards the outcome is deterministic: use compare, show Win % and Tie %.
      if (comm.length == 5) {
        var winnerIdx = 0;
        for (var i = 1; i < players.length; i++) {
          final r = await widget.api.compare(
            hand1Hole: players[winnerIdx].hole,
            hand1Community: comm,
            hand2Hole: players[i].hole,
            hand2Community: comm,
          );
          if (r.winner == 'hand2') winnerIdx = i;
        }
        final winnerIndices = <int>[winnerIdx];
        for (var i = 0; i < players.length; i++) {
          if (i == winnerIdx) continue;
          final r = await widget.api.compare(
            hand1Hole: players[winnerIdx].hole,
            hand1Community: comm,
            hand2Hole: players[i].hole,
            hand2Community: comm,
          );
          if (r.winner == 'tie') winnerIndices.add(i);
        }
        final nWinners = winnerIndices.length;
        final playersResult = <({int playerNum, String winPct, String tiePct})>[];
        for (var i = 0; i < players.length; i++) {
          final isTie = nWinners > 1 && winnerIndices.contains(i);
          final isWinner = winnerIndices.contains(i);
          final win = isWinner && !isTie ? 100.0 : 0.0;
          final tie = isTie ? 100.0 : 0.0;
          playersResult.add((
            playerNum: players[i].playerNum,
            winPct: '${win.toStringAsFixed(2)}%',
            tiePct: '${tie.toStringAsFixed(2)}%',
          ));
        }
        setState(() {
          _result = _WinProbabilityResult(board: comm, players: playersResult);
          _loading = false;
        });
        return;
      }

      final nSims = int.tryParse(_numSims.text) ?? 10000;
      if (nSims < 1 || nSims > 500000) {
        setState(() {
          _error = 'Simulations 1–500000';
          _loading = false;
        });
        return;
      }
      // One simulation with all players' hole cards so win% + tie% sum to 100%
      final r = await widget.api.winProbabilityMulti(
        playersHoleCards: players.map((p) => p.hole).toList(),
        communityCards: comm,
        numSimulations: nSims,
      );
      final playersResult = <({int playerNum, String winPct, String tiePct})>[];
      for (var i = 0; i < players.length; i++) {
        final p = r.players[i];
        playersResult.add((
          playerNum: players[i].playerNum,
          winPct: '${(p.winProbability * 100).toStringAsFixed(2)}%',
          tiePct: '${(p.tieProbability * 100).toStringAsFixed(2)}%',
        ));
      }
      setState(() {
        _result = _WinProbabilityResult(board: comm, players: playersResult);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final players = _activePlayers();
    final canRun = widget.canCalculate && players.length >= 2;
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Win % and Tie % for each active player (Monte Carlo when board is incomplete; deterministic when 5 board cards).'),
          if (widget.blockMessage != null) ...[
            const SizedBox(height: 6),
            Text(widget.blockMessage!, style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: _numSims,
            decoration: const InputDecoration(labelText: 'Simulations (used when board has 0, 3, or 4 cards)'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: (_loading || !canRun) ? null : _run,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Calculate'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            if (_result!.board.isNotEmpty) ...[
              Text('Board', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CardDisplayRow(cards: _result!.board),
                ),
              ),
              const SizedBox(height: 14),
            ],
            ...List.generate(_result!.players.length, (i) {
              final p = _result!.players[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text('P${p.playerNum}', style: theme.textTheme.titleSmall),
                        const SizedBox(width: 16),
                        Text('Win: ${p.winPct}  Tie: ${p.tiePct}', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
