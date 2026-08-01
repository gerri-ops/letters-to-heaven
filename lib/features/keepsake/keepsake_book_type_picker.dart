import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import 'keepsake_catalog.dart';

class KeepsakeBookTypePicker extends StatelessWidget {
  const KeepsakeBookTypePicker({
    required this.selected,
    required this.onChanged,
    this.entries = const [],
    super.key,
  });

  /// Empty set means "All".
  final Set<KeepsakeBookType> selected;
  final ValueChanged<Set<KeepsakeBookType>> onChanged;
  final List<Entry> entries;

  @override
  Widget build(BuildContext context) {
    final available = availableBookTypesFor(entries);
    final allSelected = selected.isEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BookChip(
          label: 'All',
          selected: allSelected,
          onTap: () => onChanged({}),
        ),
        for (final book in available)
          _BookChip(
            label: book.shortLabel,
            selected: selected.contains(book),
            onTap: () {
              final next = Set<KeepsakeBookType>.from(selected);
              if (next.contains(book)) {
                next.remove(book);
              } else {
                next.add(book);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}

class _BookChip extends StatelessWidget {
  const _BookChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.softBlush : AppColors.parchment,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.cardinalRed : AppColors.softBlush,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.burgundy,
                ),
          ),
        ),
      ),
    );
  }
}
