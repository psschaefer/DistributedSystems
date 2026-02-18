import 'package:flutter/material.dart';

/// Read-only card display (same style as table cards): white card with suit, no text field.
class CardDisplay extends StatelessWidget {
  const CardDisplay({super.key, required this.card});

  final String card;

  static (String, bool)? _suitFromCard(String c) {
    final s = c.trim().toUpperCase();
    if (s.isEmpty || s.length < 2) return null;
    switch (s[0]) {
      case 'H': return ('♥', true);
      case 'S': return ('♠', false);
      case 'D': return ('♦', true);
      case 'C': return ('♣', false);
      default: return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final suitInfo = _suitFromCard(card);
    final suitSymbol = suitInfo?.$1;
    final suitRed = suitInfo?.$2 ?? true;
    final suitColor = suitRed ? const Color(0xFFC62828) : const Color(0xFF212121);
    final display = card.trim().toUpperCase();

    return SizedBox(
      width: 36,
      height: 48,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE0E0E0)),
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
              Text(
                display,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: suitInfo != null ? suitColor : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row of read-only cards (e.g. best hand of 5).
class CardDisplayRow extends StatelessWidget {
  const CardDisplayRow({super.key, required this.cards});

  final List<String> cards;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: cards.map((c) => CardDisplay(card: c)).toList(),
    );
  }
}
