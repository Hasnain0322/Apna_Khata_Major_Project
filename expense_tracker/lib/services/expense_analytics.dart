// lib/services/expense_analytics.dart

import 'package:expense_tracker/models/expense_model.dart';
import 'package:intl/intl.dart';

class ExpenseAnalytics {
  // Get total spending for a time period
  static double getTotalSpending(
    List<Expense> expenses, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _filterByDateRange(
      expenses,
      startDate,
      endDate,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get spending by category
  static Map<String, double> getCategoryBreakdown(
    List<Expense> expenses, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredExpenses = _filterByDateRange(
      expenses,
      startDate,
      endDate,
    );
    final Map<String, double> categoryTotals = {};

    for (final expense in filteredExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) +
          expense.amount;
    }

    return categoryTotals;
  }

  // Get spending for specific category
  static double getCategorySpending(
    List<Expense> expenses,
    String category, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _filterByDateRange(expenses, startDate, endDate)
        .where(
          (expense) =>
              expense.category.toLowerCase() ==
              category.toLowerCase(),
        )
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get top N expenses
  static List<Expense> getTopExpenses(
    List<Expense> expenses, {
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final filteredExpenses = _filterByDateRange(
      expenses,
      startDate,
      endDate,
    );
    final sortedExpenses = List<Expense>.from(
      filteredExpenses,
    );
    sortedExpenses.sort(
      (a, b) => b.amount.compareTo(a.amount),
    );
    return sortedExpenses.take(limit).toList();
  }

  // Get recent expenses
  static List<Expense> getRecentExpenses(
    List<Expense> expenses, {
    int limit = 5,
  }) {
    final sortedExpenses = List<Expense>.from(expenses);
    sortedExpenses.sort(
      (a, b) => b.timestamp.compareTo(a.timestamp),
    );
    return sortedExpenses.take(limit).toList();
  }

  // Get this month's spending
  static double getThisMonthSpending(
    List<Expense> expenses,
  ) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return getTotalSpending(
      expenses,
      startDate: startOfMonth,
    );
  }

  // Get last month's spending for comparison
  static double getLastMonthSpending(
    List<Expense> expenses,
  ) {
    final now = DateTime.now();
    final startOfLastMonth = DateTime(
      now.year,
      now.month - 1,
      1,
    );
    final endOfLastMonth = DateTime(
      now.year,
      now.month,
      1,
    ).subtract(const Duration(days: 1));
    return getTotalSpending(
      expenses,
      startDate: startOfLastMonth,
      endDate: endOfLastMonth,
    );
  }

  // Search expenses by item name
  static List<Expense> searchExpenses(
    List<Expense> expenses,
    String searchTerm,
  ) {
    return expenses
        .where(
          (expense) => expense.item.toLowerCase().contains(
            searchTerm.toLowerCase(),
          ),
        )
        .toList();
  }

  // Helper method to filter expenses by date range
  static List<Expense> _filterByDateRange(
    List<Expense> expenses,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return expenses.where((expense) {
      final expenseDate = expense.timestamp.toDate();

      if (startDate != null &&
          expenseDate.isBefore(startDate)) {
        return false;
      }

      if (endDate != null && expenseDate.isAfter(endDate)) {
        return false;
      }

      return true;
    }).toList();
  }

  // Format currency for display
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Get formatted date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Extract category from user query (simple version)
  static String? extractCategoryFromQuery(String query) {
    final commonCategories = [
      'food',
      'transport',
      'entertainment',
      'shopping',
      'bills',
      'health',
      'education',
      'travel',
      'groceries',
      'restaurant',
    ];

    final lowerQuery = query.toLowerCase();

    for (final category in commonCategories) {
      if (lowerQuery.contains(category)) {
        return category.toLowerCase();
      }
    }

    return null;
  }
}
