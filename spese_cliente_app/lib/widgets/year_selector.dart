import 'package:flutter/material.dart';
import 'package:spese_cliente_app/l10n/strings.dart';

/// Horizontal row of chips to pick a year, or null for "all years".
class YearSelector extends StatelessWidget {
  final List<int> years;
  final int? selected;
  final ValueChanged<int?> onChanged;

  const YearSelector({
    super.key,
    required this.years,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          for (final year in years)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('year_chip_$year'),
                label: Text('$year'),
                selected: selected == year,
                onSelected: (_) => onChanged(year),
              ),
            ),
          ChoiceChip(
            key: const Key('year_chip_all'),
            label: Text(s.allYears),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
        ],
      ),
    );
  }
}
