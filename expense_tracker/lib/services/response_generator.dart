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
      // Navigation: ensure add-expense gives add guidance only
      case QueryIntent.navigationAddExpense:
        return _generateAddExpenseHowTo(userName);

      case QueryIntent.navigationReports:
        return _generateNavigationResponse(
          'Reports show your analytics and breakdowns:',
          [
            '📊 Weekly Analytics',
            '📈 Monthly Trends',
            '🥧 Category Breakdown',
          ],
          [
            QuickAction(
              label: 'Open Reports',
              type: QuickActionType.navigation,
              data: 'reports',
            ),
          ],
        );

      case QueryIntent.navigationProfile:
        return _generateNavigationResponse(
          'Manage your account and profile settings:',
          [
            '✏️ Edit Profile Info',
            '🔒 Change Password',
            '⚙️ Account Settings',
          ],
          [
            QuickAction(
              label: 'Open Profile',
              type: QuickActionType.navigation,
              data: 'profile',
            ),
          ],
        );

      case QueryIntent.navigationHistory:
        return _generateNavigationResponse(
          'View your entire expense history with filters and search:',
          [
            '📅 Filter by Date',
            '💰 Sort by Amount',
            '🔍 Search Expenses',
          ],
          [
            QuickAction(
              label: 'Open History',
              type: QuickActionType.navigation,
              data: 'history',
            ),
          ],
        );

      // Spending summaries
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

      // Search
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

      // Profile/help
      case QueryIntent.profileInfo:
        return _generateProfileInfoResponse(userProfile);
      case QueryIntent.appFeatures:
        return _generateAppFeaturesResponse(userName);
      case QueryIntent.howToUse:
        return _generateHowToUseResponse(userName);
      case QueryIntent.generalHelp:
        return _generateHelpResponse(userName);

      // Insights/budget
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

      default:
        return _generateUnknownResponse(
          userName,
          originalQuery,
        );
    }
  }

  // --- Add Expense How-To: concise + a single clear primary action
  static ChatResponse _generateAddExpenseHowTo(
    String userName,
  ) {
    final message = [
      'Here’s how to add an expense, $userName:',
      '• Tap “Open Add Expense” to enter item, amount, and category.',
      '• Optionally attach a receipt photo on the add screen.',
      '• Save to record it instantly.',
    ].join('\n');
    return ChatResponse(
      message: message,
      quickActions: [
        QuickAction(
          label: 'Open Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
    );
  }

  static ChatResponse _generateNavigationResponse(
    String intro,
    List<String> bullets,
    List<QuickAction> actions,
  ) {
    final message =
        '$intro\n\n${bullets.map((f) => '• $f').join('\n')}';
    return ChatResponse(
      message: message,
      quickActions: actions,
    );
  }

  // --- Existing handlers unchanged below
  static ChatResponse _generateTotalSpendingResponse(
    List<Expense> expenses,
    String userName,
  ) {
    if (expenses.isEmpty) {
      return ChatResponse(
        message:
            'No expenses yet, $userName. Start by adding your first expense.',
        quickActions: [
          QuickAction(
            label: 'Open Add Expense',
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

    String msg =
        'Here\'s your spending summary, $userName:\n\n';
    msg +=
        '💰 This Month: ${ExpenseAnalytics.formatCurrency(thisMonth)}\n';
    if (lastMonth > 0) {
      final diff = thisMonth - lastMonth;
      final pct = ((diff / lastMonth) * 100).abs();
      if (diff > 0) {
        msg +=
            '📈 ${ExpenseAnalytics.formatCurrency(diff)} more than last month (+${pct.toStringAsFixed(1)}%)\n';
      } else if (diff < 0) {
        msg +=
            '📉 ${ExpenseAnalytics.formatCurrency(diff.abs())} less than last month (-${pct.toStringAsFixed(1)}%)\n';
      } else {
        msg += '📊 Same as last month\n';
      }
    }
    msg +=
        '\n🎯 All Time Total: ${ExpenseAnalytics.formatCurrency(total)}';

    return ChatResponse(
      message: msg,
      quickActions: [
        QuickAction(
          label: 'Open Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
        QuickAction(
          label: 'Open Add Expense',
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
      final breakdown =
          ExpenseAnalytics.getCategoryBreakdown(expenses);
      if (breakdown.isEmpty) {
        return ChatResponse(
          message:
              'No expenses found, $userName. Try adding some expenses first.',
          quickActions: [
            QuickAction(
              label: 'Open Add Expense',
              type: QuickActionType.navigation,
              data: 'add_expense',
            ),
          ],
        );
      }
      final sorted =
          breakdown.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      String msg =
          'Your spending by category, $userName:\n\n';
      for (final e in sorted.take(5)) {
        msg +=
            '• ${_cap(e.key)}: ${ExpenseAnalytics.formatCurrency(e.value)}\n';
      }
      return ChatResponse(
        message: msg,
        quickActions: [
          QuickAction(
            label: 'Open Reports',
            type: QuickActionType.navigation,
            data: 'reports',
          ),
          QuickAction(
            label: 'Open Add Expense',
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
              'No spending on ${_cap(category)} yet, $userName.',
          quickActions: [
            QuickAction(
              label: 'Add ${_cap(category)} Expense',
              type: QuickActionType.navigation,
              data: 'add_expense',
            ),
          ],
        );
      }
      return ChatResponse(
        message:
            'You\'ve spent ${ExpenseAnalytics.formatCurrency(amount)} on ${_cap(category)} this month, $userName.',
        quickActions: [
          QuickAction(
            label: 'Open Category Report',
            type: QuickActionType.navigation,
            data: 'reports',
          ),
          QuickAction(
            label: 'Open Add Expense',
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
    final top = ExpenseAnalytics.getTopExpenses(expenses);
    if (top.isEmpty) {
      return ChatResponse(
        message:
            'No expenses found, $userName. Add some to see your biggest spends.',
        quickActions: [
          QuickAction(
            label: 'Open Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
      );
    }
    String msg = 'Your biggest expenses, $userName:\n\n';
    for (int i = 0; i < top.length; i++) {
      final e = top[i];
      msg +=
          '${i + 1}. ${e.item} - ${ExpenseAnalytics.formatCurrency(e.amount)}\n';
      msg +=
          '   📅 ${ExpenseAnalytics.formatDate(e.timestamp.toDate())}\n\n';
    }
    return ChatResponse(
      message: msg,
      quickActions: [
        QuickAction(
          label: 'Open History',
          type: QuickActionType.navigation,
          data: 'history',
        ),
        QuickAction(
          label: 'Open Add Expense',
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
    final recents = ExpenseAnalytics.getRecentExpenses(
      expenses,
    );
    if (recents.isEmpty) {
      return ChatResponse(
        message:
            'No recent expenses, $userName. Ready to add your first expense?',
        quickActions: [
          QuickAction(
            label: 'Open Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
      );
    }
    String msg = 'Your recent expenses, $userName:\n\n';
    for (final e in recents) {
      msg +=
          '• ${e.item} - ${ExpenseAnalytics.formatCurrency(e.amount)}\n';
      msg +=
          '  📁 ${_cap(e.category)} • ${ExpenseAnalytics.formatDate(e.timestamp.toDate())}\n\n';
    }
    return ChatResponse(
      message: msg,
      quickActions: [
        QuickAction(
          label: 'Open History',
          type: QuickActionType.navigation,
          data: 'history',
        ),
        QuickAction(
          label: 'Open Add Expense',
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
    String msg =
        'Monthly spending overview, $userName:\n\n';
    msg +=
        '📅 This Month: ${ExpenseAnalytics.formatCurrency(thisMonth)}\n';
    msg +=
        '📅 Last Month: ${ExpenseAnalytics.formatCurrency(lastMonth)}\n\n';
    if (thisMonth > 0 && lastMonth > 0) {
      final diff = thisMonth - lastMonth;
      if (diff > 0) {
        msg +=
            '📈 Spending ${ExpenseAnalytics.formatCurrency(diff)} more this month';
      } else if (diff < 0) {
        msg +=
            '📉 Saving ${ExpenseAnalytics.formatCurrency(diff.abs())} vs last month 🎉';
      } else {
        msg += '📊 Same spending as last month';
      }
    }
    return ChatResponse(
      message: msg,
      quickActions: [
        QuickAction(
          label: 'Open Monthly Report',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
        QuickAction(
          label: 'Open Add Expense',
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
    final weekly = ExpenseAnalytics.getTotalSpending(
      expenses,
      startDate: startOfWeek,
    );
    return ChatResponse(
      message:
          'Weekly spending, $userName: ${ExpenseAnalytics.formatCurrency(weekly)}',
      quickActions: [
        QuickAction(
          label: 'Open Reports',
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
    final daily = ExpenseAnalytics.getTotalSpending(
      expenses,
      startDate: startOfDay,
    );
    return ChatResponse(
      message:
          'Today\'s spending, $userName: ${ExpenseAnalytics.formatCurrency(daily)}',
      quickActions: [
        QuickAction(
          label: 'Open Reports',
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
    return ChatResponse(
      message:
          'Comparison: This month ${ExpenseAnalytics.formatCurrency(thisMonth)} vs last month ${ExpenseAnalytics.formatCurrency(lastMonth)}',
      quickActions: [
        QuickAction(
          label: 'Open Reports',
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
    final term =
        QueryClassifier.extractSearchTerm(query) ?? '';
    final results = ExpenseAnalytics.searchExpenses(
      expenses,
      term,
    );
    return ChatResponse(
      message:
          'Search results for "$term": ${results.length} found.',
      quickActions: [
        QuickAction(
          label: 'Open History',
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
    return ChatResponse(
      message: 'Expenses by date: feature coming soon.',
      quickActions: [
        QuickAction(
          label: 'Open History',
          type: QuickActionType.navigation,
          data: 'history',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateProfileInfoResponse(
    UserProfile? userProfile,
  ) {
    final name = userProfile?.displayName ?? 'User';
    return ChatResponse(
      message: 'Profile info for $name',
      quickActions: [
        QuickAction(
          label: 'Open Profile',
          type: QuickActionType.navigation,
          data: 'profile',
        ),
      ],
    );
  }

  static ChatResponse _generateAppFeaturesResponse(
    String userName,
  ) {
    return ChatResponse(
      message:
          'I can summarize spending, analyze budgets, show trends, and navigate to reports.',
      quickActions: [
        QuickAction(
          label: 'Open Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
    );
  }

  static ChatResponse _generateHowToUseResponse(
    String userName,
  ) {
    return ChatResponse(
      message:
          'Ask: "Analyze my budget", "Monthly spending", "Recent expenses", or "Add an expense".',
      quickActions: [
        QuickAction(
          label: 'Open Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
    );
  }

  static ChatResponse _generateHelpResponse(
    String userName,
  ) {
    return ChatResponse(
      message:
          'Try: "Monthly spending", "Top expenses", "Analyze my budget", or "Add expense".',
      quickActions: [
        QuickAction(
          label: 'Open Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
    );
  }

  static ChatResponse _generateUnknownResponse(
    String userName,
    String originalQuery,
  ) {
    return ChatResponse(
      message:
          'Sorry, that wasn\'t clear, $userName. Try "Add expense" or "Monthly spending".',
      quickActions: [
        QuickAction(
          label: 'Open Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
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
    if (insights.isEmpty) {
      return ChatResponse(
        message:
            'No insights yet, $userName. Add more expenses to unlock insights.',
        quickActions: [
          QuickAction(
            label: 'Open Add Expense',
            type: QuickActionType.navigation,
            data: 'add_expense',
          ),
        ],
      );
    }
    String msg = 'Your insights, $userName:\n\n';
    for (final i in insights) {
      msg += '${i.title}: ${i.message}\n\n';
    }
    return ChatResponse(
      message: msg,
      quickActions: [
        QuickAction(
          label: 'Open Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateSpendingTipsResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final tips = ProactiveInsights.getSpendingTips(
      expenses,
    );
    return ChatResponse(
      message:
          'Tips for you, $userName:\n\n${tips.join('\n')}',
      quickActions: [
        QuickAction(
          label: 'Open Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
      ],
      hasData: true,
    );
  }

  static ChatResponse _generateBudgetAnalysisResponse(
    List<Expense> expenses,
    String userName,
  ) {
    final total = ExpenseAnalytics.getTotalSpending(
      expenses,
    );
    final thisMonth = ExpenseAnalytics.getThisMonthSpending(
      expenses,
    );
    final lastMonth = ExpenseAnalytics.getLastMonthSpending(
      expenses,
    );
    final categories =
        ExpenseAnalytics.getCategoryBreakdown(expenses);

    String msg = 'Budget analysis, $userName:\n\n';
    msg +=
        '• Total: ${ExpenseAnalytics.formatCurrency(total)}\n';
    msg +=
        '• This Month: ${ExpenseAnalytics.formatCurrency(thisMonth)}\n';
    msg +=
        '• Last Month: ${ExpenseAnalytics.formatCurrency(lastMonth)}\n';
    if (categories.isNotEmpty) {
      final sorted =
          categories.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.take(3);
      msg += '• Top Categories:\n';
      for (final e in top) {
        msg +=
            '   - ${_cap(e.key)}: ${ExpenseAnalytics.formatCurrency(e.value)}\n';
      }
    }
    return ChatResponse(
      message: msg,
      quickActions: [
        QuickAction(
          label: 'Open Reports',
          type: QuickActionType.navigation,
          data: 'reports',
        ),
        QuickAction(
          label: 'Open Add Expense',
          type: QuickActionType.navigation,
          data: 'add_expense',
        ),
      ],
      hasData: true,
    );
  }

  static String _cap(String s) =>
      s.isEmpty
          ? s
          : s[0].toUpperCase() +
              s.substring(1).toLowerCase();
}
