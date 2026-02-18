import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Japanese-style background: gradient + seigaiha-inspired wave pattern.
class _JapaneseBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Deep gradient: dark crimson / black
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF1A0A0A),
        const Color(0xFF2D1515),
        const Color(0xFF1A0A0A),
        const Color(0xFF0D0505),
      ],
      stops: const [0.0, 0.35, 0.65, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Seigaiha-style arcs (concentric semicircles) in subtle gold
    const arcStep = 32.0;
    const radiusStep = 16.0;
    final paint = Paint()
      ..color = const Color(0x22C9A227)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    for (var row = 0.0; row < size.height + arcStep * 2; row += arcStep) {
      for (var col = 0.0; col < size.width + arcStep * 2; col += arcStep) {
        final base = Offset(col, row);
        for (var r = radiusStep; r < radiusStep * 6; r += radiusStep) {
          canvas.drawCircle(base, r, paint);
        }
      }
    }

    // Vignette: darker edges
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 0.9,
      colors: [Colors.transparent, const Color(0x20000000), const Color(0x50000000)],
      stops: const [0.5, 0.8, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// One poker table: 10 seats around the edge, one community card area (Flop / Turn / River) in the center.
/// [seatPlayerNumbers]: P1..P10 by add order (null = no player).
class PokerTable extends StatelessWidget {
  const PokerTable({
    super.key,
    required this.seatHoleCards,
    required this.seatPlayerNumbers,
    required this.communityCards,
    required this.onAddSeat,
    required this.onRemoveSeat,
    required this.onCardChanged,
    required this.usedCardsCount,
  });

  final List<List<TextEditingController>?> seatHoleCards;
  final List<int?> seatPlayerNumbers;
  final List<TextEditingController> communityCards;
  final ValueChanged<int> onAddSeat;
  final ValueChanged<int> onRemoveSeat;
  final VoidCallback onCardChanged;
  final Map<String, int> usedCardsCount;

  static const int _seatCount = 10;

  bool _isUnavailable(String card) {
    if (card.isEmpty) return false;
    return (usedCardsCount[card] ?? 0) > 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;
        const seatMargin = 24.0;
        final ry = (h / 2 - seatMargin).clamp(80.0, 380.0);
        final maxRx = w / 2 - seatMargin;
        // Wide oval: middle longer (rx large), use full width
        final rx = maxRx.clamp(180.0, 600.0);
        final tableW = rx * 2;
        final tableH = ry * 2;
        // Seats closer to middle (inner ring)
        const seatInset = 0.72;
        final seatRx = rx * seatInset;
        final seatRy = ry * seatInset;
        return Stack(
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          children: [
            // Japanese-style background (full area)
            Positioned.fill(
              child: CustomPaint(painter: _JapaneseBackgroundPainter()),
            ),
            // Table: outer rail (oval) – 3D with strong shadow and highlight
            Center(
              child: Container(
                width: tableW + 24,
                height: tableH + 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF5D4037),
                      const Color(0xFF3E2723),
                      const Color(0xFF2C1810),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: -2, offset: const Offset(0, 10)),
                    BoxShadow(color: Colors.black38, blurRadius: 12, offset: const Offset(0, 6)),
                    BoxShadow(color: const Color(0x1AFFFFFF), blurRadius: 4, offset: const Offset(-2, -3)),
                  ],
                ),
              ),
            ),
            // Table edge (thickness band) – 3D rim
            Center(
              child: Container(
                width: tableW + 12,
                height: tableH + 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.95,
                    colors: [
                      const Color(0xFF1B0F0A),
                      const Color(0xFF0D0502),
                    ],
                  ),
                ),
              ),
            ),
            // Table felt (oval) – recessed, 3D with shadows
            Center(
              child: Container(
                width: tableW,
                height: tableH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.92,
                    colors: [
                      const Color(0xFF388E3C),
                      const Color(0xFF2E7D32),
                      const Color(0xFF1B5E20),
                      const Color(0xFF0D3310),
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 14, offset: const Offset(0, 6)),
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(0, 2)),
                    const BoxShadow(color: Color(0x18000000), blurRadius: 8, spreadRadius: -4),
                  ],
                ),
              ),
            ),
            Center(
              child: _CommunityCardArea(
                controllers: communityCards,
                onCardChanged: onCardChanged,
                usedCardsCount: usedCardsCount,
              ),
            ),
            ...List.generate(_seatCount, (i) {
              final angleDeg = 270.0 + i * 360.0 / _seatCount;
              final angleRad = angleDeg * math.pi / 180;
              final x = cx + seatRx * math.cos(angleRad);
              final y = cy + seatRy * math.sin(angleRad);
              final hasPlayer = seatHoleCards[i] != null;
              return Positioned(
                left: x - 44,
                top: y - 40,
                child: _SeatWidget(
                  playerNumber: seatPlayerNumbers[i],
                  hasPlayer: hasPlayer,
                  holeCards: seatHoleCards[i],
                  onAdd: () => onAddSeat(i),
                  onRemove: () => onRemoveSeat(i),
                  onCardChanged: onCardChanged,
                  usedCardsCount: usedCardsCount,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _CommunityCardArea extends StatelessWidget {
  const _CommunityCardArea({
    required this.controllers,
    required this.onCardChanged,
    required this.usedCardsCount,
  });

  final List<TextEditingController> controllers;
  final VoidCallback onCardChanged;
  final Map<String, int> usedCardsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LabeledCards(
                label: 'Flop',
                controllers: controllers.sublist(0, 3),
                onCardChanged: onCardChanged,
                usedCardsCount: usedCardsCount,
              ),
              const SizedBox(width: 8),
              _LabeledCards(
                label: 'Turn',
                controllers: controllers.sublist(3, 4),
                onCardChanged: onCardChanged,
                usedCardsCount: usedCardsCount,
              ),
              const SizedBox(width: 8),
              _LabeledCards(
                label: 'River',
                controllers: controllers.sublist(4, 5),
                onCardChanged: onCardChanged,
                usedCardsCount: usedCardsCount,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledCards extends StatelessWidget {
  const _LabeledCards({
    required this.label,
    required this.controllers,
    required this.onCardChanged,
    required this.usedCardsCount,
  });

  final String label;
  final List<TextEditingController> controllers;
  final VoidCallback onCardChanged;
  final Map<String, int> usedCardsCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < controllers.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _MiniCardField(
                  controller: controllers[i],
                  onChanged: onCardChanged,
                  isUnavailable: _checkUnavailable(controllers[i].text),
                ),
              ),
          ],
        ),
      ],
    );
  }

  bool _checkUnavailable(String value) {
    final card = value.trim().toUpperCase();
    if (card.isEmpty) return false;
    return (usedCardsCount[card] ?? 0) > 1;
  }
}

class _SeatWidget extends StatelessWidget {
  const _SeatWidget({
    required this.playerNumber,
    required this.hasPlayer,
    required this.holeCards,
    required this.onAdd,
    required this.onRemove,
    required this.onCardChanged,
    required this.usedCardsCount,
  });

  final int? playerNumber;
  final bool hasPlayer;
  final List<TextEditingController>? holeCards;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onCardChanged;
  final Map<String, int> usedCardsCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hasPlayer)
            FilledButton.tonal(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Add'),
            )
          else ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniCardField(
                  controller: holeCards![0],
                  onChanged: onCardChanged,
                  isUnavailable: _checkUnavailable(holeCards![0].text),
                ),
                const SizedBox(width: 4),
                _MiniCardField(
                  controller: holeCards![1],
                  onChanged: onCardChanged,
                  isUnavailable: _checkUnavailable(holeCards![1].text),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('P$playerNumber', style: Theme.of(context).textTheme.labelSmall),
            TextButton(
              onPressed: onRemove,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Remove', style: TextStyle(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  bool _checkUnavailable(String value) {
    final card = value.trim().toUpperCase();
    if (card.isEmpty) return false;
    return (usedCardsCount[card] ?? 0) > 1;
  }
}

/// Suit symbol and color from card code (e.g. HA -> ♥ red). Returns (symbol, isRed).
(String, bool)? _suitFromCard(String card) {
  final c = card.trim().toUpperCase();
  if (c.isEmpty || c.length < 2) return null;
  switch (c[0]) {
    case 'H': return ('♥', true);
    case 'S': return ('♠', false);
    case 'D': return ('♦', true);
    case 'C': return ('♣', false);
    default: return null;
  }
}

/// Card text field: white card with heart/spade/diamond/club background based on input; "Card not available" when duplicate.
class _MiniCardField extends StatefulWidget {
  const _MiniCardField({
    required this.controller,
    required this.onChanged,
    required this.isUnavailable,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool isUnavailable;

  @override
  State<_MiniCardField> createState() => _MiniCardFieldState();
}

class _MiniCardFieldState extends State<_MiniCardField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_listen);
  }

  @override
  void didUpdateWidget(_MiniCardField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_listen);
      widget.controller.addListener(_listen);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_listen);
    super.dispose();
  }

  void _listen() => widget.onChanged();

  @override
  Widget build(BuildContext context) {
    final card = widget.controller.text.trim().toUpperCase();
    final suitInfo = _suitFromCard(card);
    final suitSymbol = suitInfo?.$1;
    final suitRed = suitInfo?.$2 ?? true;
    final suitColor = suitRed ? const Color(0xFFC62828) : const Color(0xFF212121);

    final child = SizedBox(
      width: 36,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: widget.isUnavailable ? Theme.of(context).colorScheme.error : const Color(0xFFE0E0E0),
            width: widget.isUnavailable ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (suitSymbol != null)
                Center(
                  child: Text(
                    suitSymbol,
                    style: TextStyle(
                      fontSize: 24,
                      color: suitColor.withOpacity(0.28),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              TextField(
                controller: widget.controller,
                maxLength: 2,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: suitInfo != null ? suitColor : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: '—',
                  counterText: '',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  errorText: widget.isUnavailable ? ' ' : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (widget.isUnavailable) {
      return Tooltip(
        message: 'Card not available',
        child: child,
      );
    }
    return child;
  }
}
