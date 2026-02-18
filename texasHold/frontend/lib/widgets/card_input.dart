import 'package:flutter/material.dart';

/// Section of [cardCount] text fields for card input (e.g. HA, S7).
class CardInputSection extends StatelessWidget {
  const CardInputSection({
    super.key,
    required this.label,
    required this.controllers,
    required this.cardCount,
  });

  final String label;
  final List<TextEditingController> controllers;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(cardCount, (i) {
              return SizedBox(
                width: 56,
                child: TextField(
                  controller: i < controllers.length ? controllers[i] : null,
                  maxLength: 2,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: i == 0 ? 'HA' : '',
                    counterText: '',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
