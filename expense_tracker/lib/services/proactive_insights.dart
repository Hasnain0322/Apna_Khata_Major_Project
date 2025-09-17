// lib/services/proactive_insights.dart

import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/services/expense_analytics.dart';
import 'package:intl/intl.dart';

class ProactiveInsights {
  static List<InsightCard> generateInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];

    if (expenses.isEmpty) {
      insights.add(
        InsightCard(
          type: InsightType.welcome,
          title: '🌟 Welcome to Smart Tracking!',
          message:
              'Start adding expenses to unlock personalized insights about your spending patterns.',
          priority: InsightPriority.high,
        ),
      );
      return insights;
    }

    insights.addAll(
      _getMonthlyComparisonInsights(expenses),
    );
    insights.addAll(_getCategoryInsights(expenses));
    insights.addAll(_getSpendingPatternInsights(expenses));
    insights.addAll(_getGoalInsights(expenses));
    insights.addAll(_getWeeklyTrendInsights(expenses));

    // New: Budget variance and trend insights
    insights.addAll(_getBudgetVarianceInsights(expenses));
    insights.addAll(_getExpenseTrendInsights(expenses));

    insights.sort(
      (a, b) =>
          b.priority.index.compareTo(a.priority.index),
    );
    return insights.take(5).toList();
  }

  static List<InsightCard> _getMonthlyComparisonInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];
    final thisMonth = ExpenseAnalytics.getThisMonthSpending(
      expenses,
    );
    final lastMonth = ExpenseAnalytics.getLastMonthSpending(
      expenses,
    );

    if (lastMonth == 0) {
      insights.add(
        InsightCard(
          type: InsightType.trend,
          title: '📊 First Month Tracking',
          message:
              'Great start! You\'ve spent ${ExpenseAnalytics.formatCurrency(thisMonth)} this month. Keep tracking to see monthly trends.',
          priority: InsightPriority.medium,
          actionText: 'View Monthly Report',
          actionData: 'monthly spending',
        ),
      );
      return insights;
    }

    if (thisMonth == 0 && lastMonth == 0) {
      return insights; // No data to compare
    }

    final difference = thisMonth - lastMonth;
    final percentChange =
        lastMonth != 0
            ? ((difference / lastMonth) * 100).abs()
            : 0.0;

    if (difference > 0 && percentChange > 20) {
      insights.add(
        InsightCard(
          type: InsightType.warning,
          title: '⚠️ Spending Alert',
          message:
              'You\'ve spent ${ExpenseAnalytics.formatCurrency(difference)} more this month (+${percentChange.toStringAsFixed(1)}%). Consider reviewing your budget.',
          priority: InsightPriority.high,
          actionText: 'See Where I Spent More',
          actionData: 'category breakdown',
        ),
      );
    } else if (difference < 0 && percentChange > 15) {
      insights.add(
        InsightCard(
          type: InsightType.achievement,
          title: '🎉 Great Savings!',
          message:
              'Awesome! You saved ${ExpenseAnalytics.formatCurrency(difference.abs())} this month (-${percentChange.toStringAsFixed(1)}%).',
          priority: InsightPriority.high,
          actionText: 'See My Savings',
          actionData: 'compare months',
        ),
      );
    } else if (percentChange <= 20) {
      insights.add(
        InsightCard(
          type: InsightType.neutral,
          title: '📈 Consistent Spending',
          message:
              'Your spending is similar to last month (${percentChange.toStringAsFixed(1)}% change). You\'re maintaining good consistency!',
          priority: InsightPriority.medium,
          actionText: 'View Trends',
          actionData: 'monthly trends',
        ),
      );
    }

    return insights;
  }

  static List<InsightCard> _getCategoryInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];
    final categoryBreakdown =
        ExpenseAnalytics.getCategoryBreakdown(expenses);

    if (categoryBreakdown.isEmpty) return insights;

    // Find dominant category
    final sortedCategories =
        categoryBreakdown.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sortedCategories.first;
    final totalSpending = ExpenseAnalytics.getTotalSpending(
      expenses,
    );

    if (totalSpending > 0) {
      final categoryPercentage =
          (topCategory.value / totalSpending) * 100;

      if (categoryPercentage > 40) {
        insights.add(
          InsightCard(
            type: InsightType.tip,
            title:
                '💡 Category Focus: ${_capitalizeFirst(topCategory.key)}',
            message:
                '${_capitalizeFirst(topCategory.key)} accounts for ${categoryPercentage.toStringAsFixed(1)}% of your spending. Consider setting a budget for this category.',
            priority: InsightPriority.medium,
            actionText:
                'Set ${_capitalizeFirst(topCategory.key)} Budget',
            actionData: 'budget tips',
          ),
        );
      }

      // Check for unusual category spending
      final foodSpending = categoryBreakdown['food'] ?? 0;

      if (foodSpending > totalSpending * 0.3) {
        insights.add(
          InsightCard(
            type: InsightType.suggestion,
            title: '🍽️ Food Spending Insight',
            message:
                'Food expenses are ${(foodSpending / totalSpending * 100).toStringAsFixed(1)}% of your budget. Try meal planning to save more!',
            priority: InsightPriority.medium,
            actionText: 'Food Budget Tips',
            actionData: 'reduce food expenses',
          ),
        );
      }
    }

    return insights;
  }

  static List<InsightCard> _getSpendingPatternInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];

    if (expenses.length < 5)
      return insights; // Need minimum data

    // Check for high-frequency small expenses
    final smallExpenses =
        expenses.where((e) => e.amount < 200).length;
    final totalExpenses = expenses.length;

    if (smallExpenses > totalExpenses * 0.7 &&
        totalExpenses > 10) {
      final totalSmallAmount = expenses
          .where((e) => e.amount < 200)
          .fold(0.0, (sum, e) => sum + e.amount);

      insights.add(
        InsightCard(
          type: InsightType.insight,
          title: '☕ Small Expenses Add Up',
          message:
              'You have $smallExpenses small purchases totaling ${ExpenseAnalytics.formatCurrency(totalSmallAmount)}. These micro-expenses can impact your budget!',
          priority: InsightPriority.medium,
          actionText: 'Track Small Expenses',
          actionData: 'small expense tips',
        ),
      );
    }

    // Check for weekend vs weekday spending
    final weekendExpenses =
        expenses.where((e) {
          final date = e.timestamp.toDate();
          return date.weekday == DateTime.saturday ||
              date.weekday == DateTime.sunday;
        }).toList();

    final weekendSpending = weekendExpenses.fold(
      0.0,
      (sum, e) => sum + e.amount,
    );
    final totalSpending = ExpenseAnalytics.getTotalSpending(
      expenses,
    );

    if (totalSpending > 0 &&
        weekendSpending > totalSpending * 0.4) {
      insights.add(
        InsightCard(
          type: InsightType.pattern,
          title: '🎯 Weekend Spending Pattern',
          message:
              'You spend ${(weekendSpending / totalSpending * 100).toStringAsFixed(1)}% of your budget on weekends. Consider planning weekend activities in advance.',
          priority: InsightPriority.low,
          actionText: 'Weekend Budget Tips',
          actionData: 'weekend spending tips',
        ),
      );
    }

    return insights;
  }

  static List<InsightCard> _getGoalInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];
    final monthlySpending =
        ExpenseAnalytics.getThisMonthSpending(expenses);

    if (monthlySpending == 0) return insights;

    // Suggest daily spending rate
    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;

    if (daysPassed > 0) {
      final dailyRate = monthlySpending / daysPassed;
      final projectedMonthly = dailyRate * daysInMonth;

      if (daysPassed > 10) {
        insights.add(
          InsightCard(
            type: InsightType.projection,
            title: '📊 Monthly Projection',
            message:
                'At your current rate of ${ExpenseAnalytics.formatCurrency(dailyRate)}/day, you\'ll spend ${ExpenseAnalytics.formatCurrency(projectedMonthly)} this month.',
            priority: InsightPriority.medium,
            actionText: 'Adjust Spending Plan',
            actionData: 'budgeting tips',
          ),
        );
      }
    }

    return insights;
  }

  static List<InsightCard> _getWeeklyTrendInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];
    final now = DateTime.now();

    // This week vs last week
    final thisWeekStart = now.subtract(
      Duration(days: now.weekday - 1),
    );
    final lastWeekStart = thisWeekStart.subtract(
      const Duration(days: 7),
    );
    final lastWeekEnd = thisWeekStart;

    final thisWeekSpending =
        ExpenseAnalytics.getTotalSpending(
          expenses,
          startDate: thisWeekStart,
        );
    final lastWeekSpending =
        ExpenseAnalytics.getTotalSpending(
          expenses,
          startDate: lastWeekStart,
          endDate: lastWeekEnd,
        );

    if (lastWeekSpending > 0) {
      final difference =
          thisWeekSpending - lastWeekSpending;
      final percentChange =
          ((difference / lastWeekSpending) * 100).abs();

      if (difference > 0 && percentChange > 25) {
        insights.add(
          InsightCard(
            type: InsightType.trend,
            title: '📈 Weekly Spending Up',
            message:
                'You\'ve spent ${percentChange.toStringAsFixed(1)}% more this week. Consider reviewing recent purchases.',
            priority: InsightPriority.medium,
            actionText: 'See This Week\'s Expenses',
            actionData: 'weekly spending',
          ),
        );
      }
    }

    return insights;
  }

  static List<InsightCard> _getBudgetVarianceInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];
    final categoryBreakdown =
        ExpenseAnalytics.getCategoryBreakdown(expenses);

    // Example assumed budgets (integrate with user settings in production)
    final budgets = {
      'food': 5000.0,
      'transport': 3000.0,
      'shopping': 4000.0,
      // Add more
    };

    budgets.forEach((category, budget) {
      final spent = categoryBreakdown[category] ?? 0.0;
      final variance = spent - budget;
      if (variance > 0) {
        insights.add(
          InsightCard(
            type: InsightType.warning,
            title:
                '⚠️ Overspending in ${_capitalizeFirst(category)}',
            message:
                'You\'ve spent ${ExpenseAnalytics.formatCurrency(spent)} vs. budget of ${ExpenseAnalytics.formatCurrency(budget)} (+${(variance / budget * 100).toStringAsFixed(1)}%). Consider cutting back.',
            priority: InsightPriority.high,
          ),
        );
      } else if (variance < 0) {
        insights.add(
          InsightCard(
            type: InsightType.achievement,
            title:
                '🎉 Under Budget in ${_capitalizeFirst(category)}',
            message:
                'Great job! Saved ${ExpenseAnalytics.formatCurrency(variance.abs())} under budget.',
            priority: InsightPriority.medium,
          ),
        );
      }
    });

    return insights;
  }

  static List<InsightCard> _getExpenseTrendInsights(
    List<Expense> expenses,
  ) {
    final insights = <InsightCard>[];
    final thisMonth = ExpenseAnalytics.getThisMonthSpending(
      expenses,
    );
    final lastMonth = ExpenseAnalytics.getLastMonthSpending(
      expenses,
    );

    if (lastMonth > 0) {
      final difference = thisMonth - lastMonth;
      final percentChange =
          ((difference / lastMonth) * 100).abs();

      if (difference > 0 && percentChange > 10) {
        insights.add(
          InsightCard(
            type: InsightType.trend,
            title: '📈 Spending Trend Up',
            message:
                'Your spending increased by ${percentChange.toStringAsFixed(1)}% this month. Top categories contributing: Food, Transport.',
            priority: InsightPriority.medium,
          ),
        );
      } else if (difference < 0 && percentChange > 10) {
        insights.add(
          InsightCard(
            type: InsightType.trend,
            title: '📉 Spending Trend Down',
            message:
                'Good work! Spending decreased by ${percentChange.toStringAsFixed(1)}% this month.',
            priority: InsightPriority.medium,
          ),
        );
      }
    }

    return insights;
  }

  static List<String> getSpendingTips(
    List<Expense> expenses,
  ) {
    final tips = <String>[];

    if (expenses.isEmpty) {
      return [
        'Start tracking expenses to get personalized tips!',
      ];
    }

    final categoryBreakdown =
        ExpenseAnalytics.getCategoryBreakdown(expenses);
    final totalSpending = ExpenseAnalytics.getTotalSpending(
      expenses,
    );

    // Category-specific tips
    if (categoryBreakdown.isNotEmpty && totalSpending > 0) {
      final foodSpending = categoryBreakdown['food'] ?? 0;
      final groceriesSpending =
          categoryBreakdown['groceries'] ?? 0;

      if (foodSpending > groceriesSpending * 2 &&
          foodSpending > 0) {
        tips.add(
          '💡 Try cooking more at home - you spend more on dining out than groceries!',
        );
      }

      final transportSpending =
          categoryBreakdown['transport'] ?? 0;
      if (transportSpending > totalSpending * 0.2) {
        tips.add(
          '🚗 Consider carpooling or public transport to reduce travel costs',
        );
      }

      final entertainmentSpending =
          categoryBreakdown['entertainment'] ?? 0;
      if (entertainmentSpending > totalSpending * 0.15) {
        tips.add(
          '🎬 Look for free entertainment options like parks, libraries, or community events',
        );
      }
    }

    // General tips
    tips.add(
      '📊 Set monthly budgets for your top spending categories',
    );
    tips.add(
      '💳 Review your expenses weekly to stay on track',
    );
    tips.add(
      '🎯 Try the 50/30/20 rule: 50% needs, 30% wants, 20% savings',
    );

    return tips.take(3).toList();
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() +
        text.substring(1).toLowerCase();
  }
}

class InsightCard {
  final InsightType type;
  final String title;
  final String message;
  final InsightPriority priority;
  final String? actionText;
  final String? actionData;

  InsightCard({
    required this.type,
    required this.title,
    required this.message,
    required this.priority,
    this.actionText,
    this.actionData,
  });
}

enum InsightType {
  achievement,
  warning,
  tip,
  trend,
  suggestion,
  insight,
  pattern,
  projection,
  neutral,
  welcome,
}

enum InsightPriority { low, medium, high }
