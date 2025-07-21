import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Helper method to process raw expense data into chart-ready data
  Map<String, double> _processExpenseData(List<Expense> expenses) {
    Map<String, double> categoryData = {};
    for (var expense in expenses) {
      if (categoryData.containsKey(expense.category)) {
        categoryData[expense.category] = categoryData[expense.category]! + expense.amount;
      } else {
        categoryData[expense.category] = expense.amount;
      }
    }
    return categoryData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Reports'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Expense>>(
        stream: _firestoreService.getExpensesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No expense data available to generate a report.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // Process the data for the chart
          final expenses = snapshot.data!;
          final Map<String, double> categoryData = _processExpenseData(expenses);
          final double totalExpenses = categoryData.values.fold(0, (sum, amount) => sum + amount);
          
          // Generate colors for each section
          final List<Color> colorPalette = [
            Colors.blue, Colors.red, Colors.green, Colors.orange, 
            Colors.purple, Colors.yellow, Colors.cyan, Colors.pink
          ];

          int colorIndex = 0;
          final List<PieChartSectionData> pieChartSections = categoryData.entries.map((entry) {
            final color = colorPalette[colorIndex % colorPalette.length];
            colorIndex++;
            final percentage = (entry.value / totalExpenses) * 100;

            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
              // Optional: Add a badge for the category name
              badgeWidget: _buildCategoryBadge(entry.key, color),
              badgePositionPercentageOffset: .98,
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Total Spending: ₹${totalExpenses.toStringAsFixed(2)}',
                   style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 300,
                  child: PieChart(
                    PieChartData(
                      sections: pieChartSections,
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          // Here you can handle touch events, e.g., make the touched section larger
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Breakdown by Category',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // Display the legend
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: categoryData.entries.map((entry) {
                    final color = colorPalette[categoryData.keys.toList().indexOf(entry.key) % colorPalette.length];
                    return _buildLegendItem(color, entry.key, entry.value);
                  }).toList(),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper widget for the legend items
  Widget _buildLegendItem(Color color, String category, double amount) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
      label: Text('$category: ₹${amount.toStringAsFixed(0)}'),
      backgroundColor: const Color(0xFF2A2A2A),
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  // Helper widget for the badges on the chart itself
  Widget _buildCategoryBadge(String category, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}