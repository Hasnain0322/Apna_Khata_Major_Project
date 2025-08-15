import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/utils/app_theme.dart';
import 'package:expense_tracker/widgets/custom-card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  int pieTouchedIndex = -1;
  int barTouchedIndex = -1;

  Map<String, double> _processCategoryData(List<Expense> expenses) {
    final Map<String, double> categoryData = {};
    for (var e in expenses) {
      categoryData[e.category] = (categoryData[e.category] ?? 0) + e.amount;
    }
    return categoryData;
  }

  Map<String, double> _processWeeklyData(List<Expense> expenses) {
    final Map<String, double> weekly = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      weekly[DateFormat.E().format(day)] = 0.0;
    }
    for (var e in expenses) {
      final d = e.timestamp.toDate();
      if (now.difference(d).inDays < 7) {
        final k = DateFormat.E().format(d);
        if (weekly.containsKey(k)) weekly[k] = weekly[k]! + e.amount;
      }
    }
    return weekly;
  }

  Map<String, double> _processMonthlyTrend(List<Expense> expenses) {
    final Map<String, double> monthly = {};
    final now = DateTime.now();
    for (int i = 11; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = DateFormat.MMM().format(m);
      monthly[key] = 0.0;
    }
    for (var e in expenses) {
      final d = e.timestamp.toDate();
      final key = DateFormat.MMM().format(d);
      if (monthly.containsKey(key)) {
        monthly[key] = monthly[key]! + e.amount;
      }
    }
    return monthly;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppTokens>()!;

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Analysis')),
      body: StreamBuilder<List<Expense>>(
        stream: _firestoreService.getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text('No expense data to generate reports.', style: theme.textTheme.bodyLarge));

          final expenses = snapshot.data!;
          final categoryData = _processCategoryData(expenses);
          final weeklyData = _processWeeklyData(expenses);
          final monthlyTrend = _processMonthlyTrend(expenses);
          final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomCard(
                  elevated: true,
                  child: Column(
                    children: [
                      Text('Total Expenses', style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Text('₹${total.toStringAsFixed(2)}', style: theme.textTheme.headlineMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Weekly Bar Chart
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Analytics', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            maxY: (weeklyData.values.isEmpty ? 0 : weeklyData.values.reduce((a, b) => a > b ? a : b)) * 1.2 + 10,
                            barTouchData: BarTouchData(
                              touchCallback: (event, response) {
                                setState(() {
                                  if (!event.isInterestedForInteractions || response?.spot == null) {
                                    barTouchedIndex = -1;
                                  } else {
                                    barTouchedIndex = response!.spot!.touchedBarGroupIndex;
                                  }
                                });
                              },
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (v, meta) {
                                    final label = weeklyData.keys.elementAt(v.toInt());
                                    return SideTitleWidget(
                                      meta: meta,
                                      space: 6,
                                      child: Text(label, style: theme.textTheme.bodyMedium),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            barGroups: List.generate(weeklyData.length, (i) {
                              final isTouched = i == barTouchedIndex;
                              final entry = weeklyData.entries.elementAt(i);
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value,
                                    color: isTouched ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.6),
                                    width: isTouched ? 18 : 14,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                                  ),
                                ],
                              );
                            }),
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Monthly Line Chart
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monthly Trend', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: (monthlyTrend.length - 1).toDouble(),
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(monthlyTrend.length, (i) {
                                  final v = monthlyTrend.values.elementAt(i);
                                  return FlSpot(i.toDouble(), v);
                                }),
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary.withOpacity(0.12),
                                ),
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 2,
                                  getTitlesWidget: (v, meta) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= monthlyTrend.length) return const SizedBox.shrink();
                                    final label = monthlyTrend.keys.elementAt(i);
                                    return SideTitleWidget(meta: meta, child: Text(label, style: theme.textTheme.bodyMedium));
                                  },
                                ),
                              ),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category Donut
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category Breakdown', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            height: 160,
                            width: 160,
                            child: PieChart(
                              PieChartData(
                                centerSpaceRadius: 48,
                                sectionsSpace: 2,
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, response) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions || response?.touchedSection == null) {
                                        pieTouchedIndex = -1;
                                      } else {
                                        pieTouchedIndex = response!.touchedSection!.touchedSectionIndex;
                                      }
                                    });
                                  },
                                ),
                                sections: List.generate(categoryData.length, (i) {
                                  final entry = categoryData.entries.elementAt(i);
                                  final isTouched = i == pieTouchedIndex;
                                  final value = entry.value;
                                  final percentage = total > 0 ? (value / total) * 100 : 0;
                                  final palette = appColors.chartPalette;
                                  return PieChartSectionData(
                                    color: palette[i % palette.length],
                                    value: value,
                                    title: '${percentage.toStringAsFixed(0)}%',
                                    radius: isTouched ? 54 : 46,
                                    titleStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                }),
                              ),
                              swapAnimationDuration: const Duration(milliseconds: 800),
                              swapAnimationCurve: Curves.easeOutCubic,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryData.entries.map((e) {
                                final index = categoryData.keys.toList().indexOf(e.key);
                                final color = appColors.chartPalette[index % appColors.chartPalette.length];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Expanded(child: Text(e.key, style: theme.textTheme.bodyMedium, overflow: TextOverflow.ellipsis)),
                                      Text('₹${e.value.toStringAsFixed(0)}', style: theme.textTheme.bodyMedium),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
