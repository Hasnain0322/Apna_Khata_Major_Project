// lib/services/response_generator.dart

import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/models/user_profile_model.dart';
import 'package:expense_tracker/services/query_intent.dart';
import 'package:expense_tracker/services/expense_analytics.dart';
import 'package:expense_tracker/services/proactive_insights.dart';

class ChatResponse {
  final String message;
  final List<QuickAction> quickActions;
  final bool hasData;

  ChatResponse({
    required this.message,
    this.quickActions = const [],
    this.hasData = false,
  });
}

class QuickAction {
  final String label;
  final QuickActionType type;
  final String? data;

  QuickAction({
    required this.label,
    required this.type,
    this.data,
  });
}

enum QuickActionType { navigation, query, action }

class ResponseGenerator {
  static ChatResponse generateResponse(
    QueryIntent intent,
    List<Expense> expenses,
    UserProfile? userProfile,
    String originalQuery,
  ) {
    final userName = userProfile?.displayName ?? 'there';
    print('Generating response for intent: $intent');

    switch (intent) {
      case QueryIntent.navigationAddExpense:
        return _generateNavigationResponse(
          'Here\'s how to add an expense, $userName:', // explain first
          [
            '💰 Add Manually',
            '🎤 Voice Entry',
            '📷 Scan Receipt',
          ],
          ['add_expense'], // user taps to navigate
        );
      case QueryIntent.navigationReports:
        return _generateNavigationResponse(
          'Reports show your trends and breakdowns:',
          [
            '📊 Weekly Analytics',
            '📈 Monthly Trends',
            '🥧 Category Breakdown',
          ],
          ['reports'],
        );
      case QueryIntent.navigationProfile:
        return _generateNavigationResponse(
          'Profile lets you manage your account:',
          [
            '✏️ Edit Profile Info',
            '🔒 Change Password',
            '⚙️ Account Settings',
          ],
          ['profile'],
        );
      case QueryIntent.navigationHistory:
        return _generateNavigationResponse(
          'Your full expense history is available here:',
          [
            '📅 Filter by Date',
            '💰 Sort by Amount',
            '🔍 Search Expenses',
          ],
          ['expenses'],
        );
      case QueryIntent.totalSpending:
        return _generateTotalSpendingResponse(
          expenses,
          userName,
        );
      case QueryIntent.categorySpending:
        return _generateCategorySpendingResponse(
          expenses,
          originalQuery,
          userName,
        );
      case QueryIntent.topExpenses:
        return _generateTopExpensesResponse(
          expenses,
          userName,
        );
      case QueryIntent.recentExpenses:
        return _generateRecentExpensesResponse(
          expenses,
          userName,
        );
      case QueryIntent.monthlySpending:
        return _generateMonthlySpendingResponse(
          expenses,
          userName,
        );
      case QueryIntent.weeklySpending:
        return _generateWeeklySpendingResponse(
          expenses,
          userName,
        );
      case QueryIntent.dailySpending:
        return _generateDailySpendingResponse(
          expenses,
          userName,
        );
      case QueryIntent.expenseComparison:
        return _generateComparisonResponse(
          expenses,
          userName,
        );
      case QueryIntent.searchExpenses:
        return _generateSearchResponse(
          expenses,
          originalQuery,
          userName,
        );
      case QueryIntent.expensesByDate:
        return _generateExpensesByDateResponse(
          expenses,
          originalQuery,
          userName,
        );
      case QueryIntent.profileInfo:
        return _generateProfileInfoResponse(userProfile);
      case QueryIntent.insights:
        return _generateInsightsResponse(
          expenses,
          userName,
        );
      case QueryIntent.spendingTips:
        return _generateSpendingTipsResponse(
          expenses,
          userName,
        );
      case QueryIntent.budgetAnalysis:
        return _generateBudgetAnalysisResponse(
          expenses,
          userName,
        );
      case QueryIntent.appFeatures:
        return _generateAppFeaturesResponse(userName);
      case QueryIntent.howToUse:
        return _generateHowToUseResponse(userName);
      case QueryIntent.generalHelp:
        return _generateHelpResponse(userName);
      default:
        return _generateUnknownResponse(
          userName,
          originalQuery,
        );
    }
  }

  static ChatResponse _generateNavigationResponse(
    String intro,
    List<String> features,
    List<String> actions,
  ) {
    final message =
        '$intro\n\n${features.map((f) => '• $f').join('\n')}';
    return ChatResponse(
      message: message,
      quickActions:
          actions
              .map(
                (a) => QuickAction(
                  label: 'Open',
                  type: QuickActionType.navigation,
                  data: a,
                ),
              )
              .toList(),
    );
  }

  static ChatResponse _generateTotalSpendingResponse(
    List<Expense> expenses,
    String userName,
  ) {
    if (expenses.isEmpty) {
      return ChatResponse(
        message:
            'You haven\'t recorded any expenses yet, $userName. Would you like to add your first expense?',
        quickActions: [
          QuickAction(
            label: 'Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
      );
    }

    final thisMonth = ExpenseAnalytics.getThisMonthSpending(
      expenses,
    );
    final lastMonth = ExpenseAnalytics.getLastMonthSpending(
      expenses,
    );
    final total = ExpenseAnalytics.getTotalSpending(
      expenses,
    );

    String message =
        'Here\'s your spending summary, $userName:\n\n';
    message +=
        '💰 This Month: ${ExpenseAnalytics.formatCurrency(thisMonth)}\n';

    if (lastMonth > 0) {
      final difference = thisMonth - lastMonth;
      final percentChange =
          ((difference / lastMonth) * 100).abs();

      if (difference > 0) {
        message +=
            '📈 ${ExpenseAnalytics.formatCurrency(difference)} more than last month (+${percentChange.toStringAsFixed(1)}%)\n';
      } else if (difference < 0) {
        message +=
            '📉 ${ExpenseAnalytics.formatCurrency(difference.abs())} less than last month (-${percentChange.toStringAsFixed(1)}%)\n';
      } else {
        message += '📊 Same as last month\n';
      }
    }

    message +=
        '\n🎯 All Time Total: ${ExpenseAnalytics.formatCurrency(total)}';

    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
        QuickAction(
          label: 'Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateCategorySpendingResponse(
    List<Expense> expenses,
    String query,
    String userName,
  ) {
    final category =
        ExpenseAnalytics.extractCategoryFromQuery(query);

    if (category == null) {
      final categoryBreakdown =
          ExpenseAnalytics.getCategoryBreakdown(expenses);
      if (categoryBreakdown.isEmpty) {
        return ChatResponse(
          message:
              'No expenses found, $userName. Start by adding some expenses!',
          quickActions: [
            QuickAction(
              label: 'Add Expense',
              type: QuickActionType.navigation,
              data: 'add_expense',
            ),
          ],
        );
      }

      String message =
          'Here\'s your spending by category, $userName:\n\n';
      final sortedCategories =
          categoryBreakdown.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedCategories.take(5)) {
        message +=
            '• ${_capitalizeFirst(entry.key)}: ${ExpenseAnalytics.formatCurrency(entry.value)}\n';
      }

      return ChatResponse(
        message: message,
        quickActions: [
          QuickAction(
            label: 'View Reports',
            type: QuickActionType.navigation,
            data: 'reports',
          ),
          QuickAction(
            label: 'Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
        hasData: true,
      );
    } else {
      final amount = ExpenseAnalytics.getCategorySpending(
        expenses,
        category,
      );
      if (amount == 0) {
        return ChatResponse(
          message:
              'You haven\'t spent anything on ${_capitalizeFirst(category)} yet, $userName.',
          quickActions: [
            QuickAction(
              label:
                  'Add ${_capitalizeFirst(category)} Expense',
              type: QuickActionType.navigation,
              data: 'add_expense',
            ),
          ],
        );
      }

      return ChatResponse(
        message:
            'You\'ve spent ${ExpenseAnalytics.formatCurrency(amount)} on ${_capitalizeFirst(category)} this month, $userName.',
        quickActions: [
          QuickAction(
            label: 'View Category Details',
            type: QuickActionType.navigation,
            data: 'reports',
          ),
          QuickAction(
            label: 'Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
        hasData: true,
      );
    }
  }

  static ChatResponse _generateTopExpensesResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final topExpenses = ExpenseAnalytics.getTopExpenses(
      expenses,
    );

    if (topExpenses.isEmpty) {
      return ChatResponse(
        message:
            'No expenses found, $userName. Add some expenses to see your biggest spends!',
        quickActions: [
          QuickAction(
            label: 'Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
      );
    }

    String message =
        'Your biggest expenses, $userName:\n\n';
    for (int i = 0; i < topExpenses.length; i++) {
      final expense = topExpenses[i];
      message +=
          '${i + 1}. ${expense.item} - ${ExpenseAnalytics.formatCurrency(expense.amount)}\n';
      message +=
          '   📅 ${ExpenseAnalytics.formatDate(expense.timestamp.toDate())}\n\n';
    }

    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View All History',
          type: QuickActionType.navigation,
          data: 'history',
        ),
        QuickAction(
          label: 'Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateRecentExpensesResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final recentExpenses =
        ExpenseAnalytics.getRecentExpenses(expenses);

    if (recentExpenses.isEmpty) {
      return ChatResponse(
        message:
            'No recent expenses found, $userName. Ready to add your first expense?',
        quickActions: [
          QuickAction(
            label: 'Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
      );
    }

    String message = 'Your recent expenses, $userName:\n\n';
    for (final expense in recentExpenses) {
      message +=
          '• ${expense.item} - ${ExpenseAnalytics.formatCurrency(expense.amount)}\n';
      message +=
          '  📁 ${_capitalizeFirst(expense.category)} • ${ExpenseAnalytics.formatDate(expense.timestamp.toDate())}\n\n';
    }

    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View All History',
          type: QuickActionType.navigation,
          data: 'history',
        ),
        QuickAction(
          label: 'Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateMonthlySpendingResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final thisMonth = ExpenseAnalytics.getThisMonthSpending(
      expenses,
    );
    final lastMonth = ExpenseAnalytics.getLastMonthSpending(
      expenses,
    );

    String message =
        'Monthly spending overview, $userName:\n\n';
    message +=
        '📅 This Month: ${ExpenseAnalytics.formatCurrency(thisMonth)}\n';
    message +=
        '📅 Last Month: ${ExpenseAnalytics.formatCurrency(lastMonth)}\n\n';

    if (thisMonth > 0 && lastMonth > 0) {
      final difference = thisMonth - lastMonth;
      if (difference > 0) {
        message +=
            '📈 Spending ${ExpenseAnalytics.formatCurrency(difference)} more this month';
      } else if (difference < 0) {
        message +=
            '📉 Saving ${ExpenseAnalytics.formatCurrency(difference.abs())} compared to last month! 🎉';
      } else {
        message += '📊 Same spending as last month';
      }
    }

    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View Monthly Report',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
        QuickAction(
          label: 'Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateWeeklySpendingResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final now = DateTime.now();
    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    final weeklySpending =
        ExpenseAnalytics.getTotalSpending(
          expenses,
          startDate: startOfWeek,
        );

    String message =
        'Weekly spending, $userName: ${ExpenseAnalytics.formatCurrency(weeklySpending)}';
    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View Details',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateDailySpendingResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final dailySpending = ExpenseAnalytics.getTotalSpending(
      expenses,
      startDate: startOfDay,
    );

    String message =
        'Daily spending, $userName: ${ExpenseAnalytics.formatCurrency(dailySpending)}';
    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View Details',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateComparisonResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final thisMonth = ExpenseAnalytics.getThisMonthSpending(
      expenses,
    );
    final lastMonth = ExpenseAnalytics.getLastMonthSpending(
      expenses,
    );

    String message =
        'Comparison: This month ${ExpenseAnalytics.formatCurrency(thisMonth)}, last month ${ExpenseAnalytics.formatCurrency(lastMonth)}';
    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateSearchResponse(
    List<Expense> expenses,
    String query,
    String userName,
  ) {
    final searchTerm =
        ExpenseAnalytics.extractCategoryFromQuery(query) ??
        '';
    final searchResults = ExpenseAnalytics.searchExpenses(
      expenses,
      searchTerm,
    );

    String message =
        'Search results for $searchTerm: ${searchResults.length} items found.';
    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View All',
          type: QuickActionType.navigation,
          data: 'history',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateExpensesByDateResponse(
    List<Expense> expenses,
    String query,
    String userName,
  ) {
    String message =
        'Expenses by date: (Implementation in progress)';
    return ChatResponse(message: message, hasData: true);
  }

  static ChatResponse _generateProfileInfoResponse(
    UserProfile? userProfile,
  ) {
    final userName = userProfile?.displayName ?? 'User';
    return ChatResponse(
      message: 'Profile info for $userName',
      quickActions: [
        QuickAction(
          label: 'Edit Profile',
          type: QuickActionType.navigation,
          data: 'profile',
        ),
      ],
    );
  }

  static ChatResponse _generateAppFeaturesResponse(
    String userName,
  ) {
    return ChatResponse(message: 'App features list');
  }

  static ChatResponse _generateHowToUseResponse(
    String userName,
  ) {
    return ChatResponse(message: 'How to use guide');
  }

  static ChatResponse _generateHelpResponse(
    String userName,
  ) {
    return ChatResponse(message: 'Help information');
  }

  static ChatResponse _generateUnknownResponse(
    String userName,
    String originalQuery,
  ) {
    return ChatResponse(
      message:
          'Sorry, I didn\'t understand that, $userName. Try "how much did I spend this month?" or "analyze my budget".',
      quickActions: [
        QuickAction(
          label: 'Spending Summary',
          type: QuickActionType.query,
          data: 'how much did I spend this month?',
        ),
        QuickAction(
          label: 'Budget Analysis',
          type: QuickActionType.query,
          data: 'analyze my budget',
        ),
      ],
    );
  }

  static ChatResponse _generateInsightsResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final insights = ProactiveInsights.generateInsights(
      expenses,
    );
    String message =
        'Your personalized insights, $userName:\n\n';
    for (var insight in insights) {
      message += '${insight.title}: ${insight.message}\n\n';
    }
    return ChatResponse(message: message, hasData: true);
  }

  static ChatResponse _generateSpendingTipsResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final tips = ProactiveInsights.getSpendingTips(
      expenses,
    );
    String message =
        'Spending tips for you, $userName:\n\n${tips.join('\n')}';
    return ChatResponse(message: message, hasData: true);
  }

  static ChatResponse _generateBudgetAnalysisResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final total = ExpenseAnalytics.getTotalSpending(
      expenses,
    );
    String message =
        'Detailed budget analysis, $userName:\n\n';
    message +=
        'Total Spending: ${ExpenseAnalytics.formatCurrency(total)}\n';
    message += 'See insights for variance and trends.';
    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'View Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
      hasData: true,
    );
  }

  static String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text.toUpperCase() +
        text.substring(1).toLowerCase();
  }
}
