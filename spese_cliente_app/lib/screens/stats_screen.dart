import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spese_cliente_app/data/client_repository.dart';
import 'package:spese_cliente_app/data/material_repository.dart';
import 'package:spese_cliente_app/l10n/strings.dart';
import 'package:spese_cliente_app/providers/stats_provider.dart';
import 'package:spese_cliente_app/widgets/year_selector.dart';

class StatsScreen extends StatelessWidget {
  final int? initialYear;

  const StatsScreen({super.key, this.initialYear});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StatsProvider>(
      create: (context) => StatsProvider(
        context.read<MaterialRepository>(),
        context.read<ClientRepository>(),
        initialYear: initialYear,
      )..load(),
      child: const _StatsBody(),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final provider = context.watch<StatsProvider>();
    final stats = provider.stats;
    final year = provider.selectedYear;
    final theme = Theme.of(context);

    final List<String> labels;
    final List<double> values;
    if (year == null) {
      final yearly = provider.yearlyTotals;
      final sorted = yearly.keys.toList()..sort();
      labels = [for (final y in sorted) '$y'];
      values = [for (final y in sorted) yearly[y]!];
    } else {
      labels = [for (var m = 1; m <= 12; m++) s.monthShort(m)];
      values = stats.monthlyTotals;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.statistics,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: provider.hasError
          ? Center(child: Text(s.genericError))
          : ListView(
              children: [
                YearSelector(
                  years: provider.years,
                  selected: year,
                  onChanged: provider.selectYear,
                ),
                if (stats.count == 0 && !provider.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(s.noExpenses)),
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatTile(label: s.totalSpent, value: s.money(stats.total)),
                        _StatTile(label: s.unpaid, value: s.money(stats.unpaid)),
                        _StatTile(label: s.monthlyAverage, value: s.money(stats.averagePerMonth)),
                        if (stats.bestMonth != null)
                          _StatTile(
                            label: s.bestMonth,
                            value: s.monthName(stats.bestMonth!),
                          ),
                        _StatTile(label: s.entries, value: '${stats.count}'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      year == null ? s.expensesByYear : s.expensesByMonth,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _BarChart(
                      labels: labels,
                      values: values,
                      selectedIndex:
                          provider.selectedMonth == null ? null : provider.selectedMonth! - 1,
                      onTap: year == null ? null : (i) => provider.selectMonth(i + 1),
                    ),
                  ),
                  if (year != null && provider.selectedMonth == null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(s.tapMonthHint, style: theme.textTheme.bodySmall),
                    ),
                  if (year != null && provider.selectedMonth != null) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        s.monthDetail(s.monthName(provider.selectedMonth!), year),
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (provider.monthItems.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(s.noExpenses),
                      ),
                    for (final item in provider.monthItems)
                      ListTile(
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text(
                          '${provider.clientName(item.clientId)} · '
                          '${item.date.day.toString().padLeft(2, '0')}/'
                          '${item.date.month.toString().padLeft(2, '0')}',
                        ),
                        trailing: Text(
                          s.money(item.totalPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: item.paid ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                  ],
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
                    child: Text(
                      s.topClients,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  for (final entry in stats.topClients())
                    ListTile(
                      dense: true,
                      title: Text(entry.key),
                      trailing: Text(
                        s.money(entry.value),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  static const _barAreaHeight = 140.0;

  final List<String> labels;
  final List<double> values;
  final int? selectedIndex;
  final ValueChanged<int>? onTap;

  const _BarChart({
    required this.labels,
    required this.values,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final max = values.fold(0.0, (m, v) => v > m ? v : m);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < values.length; i++)
          Expanded(
            child: InkWell(
              key: Key('bar_$i'),
              onTap: onTap == null ? null : () => onTap!(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: _barAreaHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: max == 0 ? 2 : 2 + (_barAreaHeight - 2) * values[i] / max,
                        decoration: BoxDecoration(
                          color: i == selectedIndex ? color.tertiary : color.primary,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == selectedIndex ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
