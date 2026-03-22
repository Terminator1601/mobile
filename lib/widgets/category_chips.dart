import 'package:flutter/material.dart';

import '../main.dart';

class CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String> onSelected;
  final bool wrap;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.wrap = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = categories.map((cat) => _chip(context, cat)).toList();

    if (wrap) {
      return Wrap(spacing: 8, runSpacing: 8, children: chips);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            chips[i],
            if (i < chips.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => onSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? kGradientPurplePink : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
