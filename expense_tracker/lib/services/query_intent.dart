// lib/services/query_intent.dart
import 'dart:math';

enum QueryIntent {
  // Navigation
  navigationAddExpense,
  navigationReports,
  navigationProfile,
  navigationHistory,

  // Spending summaries
  totalSpending,
  categorySpending,
  topExpenses,
  recentExpenses,
  monthlySpending,
  weeklySpending,
  dailySpending,
  expenseComparison,

  // Search
  searchExpenses,
  expensesByDate,

  // Profile and general
  profileInfo,
  generalHelp,
  appFeatures,
  howToUse,

  // Insights and budget
  insights,
  spendingTips,
  budgetAnalysis,

  unknown,
}

class QueryClassifier {
  static QueryIntent classifyQuery(String query) {
    final q = query.toLowerCase().trim();
    print('Classifying query: $q');

    // 1) Explicit navigation phrases FIRST to avoid misclassification
    if (_matchesAddExpensePhrases(q))
      return QueryIntent.navigationAddExpense;
    if (_matchesNavigationPhrases(q))
      return _getNavigationIntent(q);

    // 2) Domain intents
    if (_matchesSpendingPatterns(q))
      return _getSpendingIntent(q);
    if (_matchesInsightPatterns(q))
      return _getInsightIntent(q);
    if (_matchesSearchPatterns(q))
      return _getSearchIntent(q);

    // 3) Profile and help
    if (_matchesProfilePatterns(q))
      return QueryIntent.profileInfo;
    if (_matchesHelpPatterns(q)) return _getHelpIntent(q);

    // 4) Fallback fuzzy
    return _fuzzyMatchIntent(q);
  }

  // --- Add Expense: strict phrases only
  static bool _matchesAddExpensePhrases(String q) {
    final phrases = [
      'how to add an expense',
      'how to add expense',
      'add an expense',
      'add expense',
      'create expense',
      'record expense',
      'log expense',
      'enter expense',
      'input expense',
      'scan receipt',
      'voice entry',
    ];
    return phrases.any((p) => q.contains(p));
  }

  // --- Other navigation phrases
  static bool _matchesNavigationPhrases(String q) {
    final phrases = [
      'open reports',
      'view reports',
      'go to reports',
      'reports page',
      'open profile',
      'go to profile',
      'account settings',
      'edit profile',
      'open history',
      'view history',
      'expense history',
      'transaction history',
    ];
    return phrases.any((p) => q.contains(p));
  }

  static QueryIntent _getNavigationIntent(String q) {
    if (_containsAny(q, [
      'open reports',
      'view reports',
      'go to reports',
      'reports page',
    ])) {
      return QueryIntent.navigationReports;
    }
    if (_containsAny(q, [
      'open profile',
      'go to profile',
      'account settings',
      'edit profile',
    ])) {
      return QueryIntent.navigationProfile;
    }
    if (_containsAny(q, [
      'open history',
      'view history',
      'expense history',
      'transaction history',
    ])) {
      return QueryIntent.navigationHistory;
    }
    return QueryIntent.unknown;
  }

  // --- Spending logic
  static bool _matchesSpendingPatterns(String q) {
    final patterns = [
      'spent',
      'spend',
      'spending',
      'expense',
      'amount',
      'total',
      'how much',
      'this month',
      'last month',
      'this week',
      'last week',
      'today',
      'daily',
      'weekly',
      'monthly',
      'compare',
      'comparison',
      'vs',
      'versus',
    ];
    return patterns.any((p) => q.contains(p));
  }

  static QueryIntent _getSpendingIntent(String q) {
    if (_containsAny(q, [
      'total spent',
      'total spending',
      'how much spent',
      'overall spending',
      'sum of expenses',
      'all expenses',
      'grand total',
      'total amount',
      'what is my total',
    ]))
      return QueryIntent.totalSpending;

    if (_containsAny(q, [
      'spent on',
      'spending on',
      'money on',
      'category',
      'category total',
    ])) {
      return QueryIntent.categorySpending;
    }

    if (_containsAny(q, [
      'biggest expense',
      'largest expense',
      'highest expense',
      'top expense',
      'top spends',
      'most expensive',
    ]))
      return QueryIntent.topExpenses;

    if (_containsAny(q, [
      'recent expense',
      'latest expense',
      'last expense',
      'recent purchases',
      'recent transactions',
      'last few expenses',
    ]))
      return QueryIntent.recentExpenses;

    if (_containsAny(q, [
      'this month',
      'monthly',
      'last month',
      'previous month',
      'month total',
    ])) {
      return QueryIntent.monthlySpending;
    }

    if (_containsAny(q, [
      'this week',
      'weekly',
      'last week',
      'week total',
    ])) {
      return QueryIntent.weeklySpending;
    }

    if (_containsAny(q, [
      'today',
      'daily',
      'yesterday',
      'per day',
      'daily total',
    ])) {
      return QueryIntent.dailySpending;
    }

    if (_containsAny(q, [
      'compare',
      'comparison',
      'vs',
      'versus',
      'trend',
      'increase',
      'decrease',
    ])) {
      return QueryIntent.expenseComparison;
    }

    return QueryIntent.totalSpending;
  }

  // --- Insights / Budget
  static bool _matchesInsightPatterns(String q) {
    final patterns = [
      'insights',
      'analyze',
      'analysis',
      'budget',
      'tips',
      'advice',
      'suggestions',
      'spending patterns',
      'how to save',
      'smart insights',
      'analyze my budget',
      'budget analysis',
      'budget breakdown',
    ];
    return patterns.any((p) => q.contains(p));
  }

  static QueryIntent _getInsightIntent(String q) {
    if (_containsAny(q, [
      'analyze my budget',
      'budget analysis',
      'budget breakdown',
      'analyze budget',
    ])) {
      return QueryIntent.budgetAnalysis;
    }
    if (_containsAny(q, [
      'spending tips',
      'save money',
      'budget tips',
      'money advice',
      'how to save',
    ])) {
      return QueryIntent.spendingTips;
    }
    if (_containsAny(q, [
      'insights',
      'spending insights',
      'analyze my spending',
      'show insights',
      'smart insights',
    ])) {
      return QueryIntent.insights;
    }
    if (q.contains('budget') &&
        (q.contains('analy') || q.contains('breakdown'))) {
      return QueryIntent.budgetAnalysis;
    }
    return QueryIntent.insights;
  }

  // --- Search
  static bool _matchesSearchPatterns(String q) {
    final patterns = [
      'search',
      'find',
      'look for',
      'filter',
      'where is',
      'when did i',
      'did i buy',
      'have i paid',
      'transactions containing',
      'expenses with',
    ];
    return patterns.any((p) => q.contains(p));
  }

  static QueryIntent _getSearchIntent(String q) {
    if (_containsAny(q, [
      'expenses on',
      'spending on date',
      'expenses by date',
      'transactions on',
      'on this date',
      'for ',
    ]))
      return QueryIntent.expensesByDate;
    return QueryIntent.searchExpenses;
  }

  // --- Profile (present and used by classifyQuery)
  static bool _matchesProfilePatterns(String q) {
    final patterns = [
      'my profile',
      'profile',
      'account info',
      'my info',
      'user info',
      'profile details',
      'account details',
      'my account',
    ];
    return patterns.any((p) => q.contains(p));
  }

  // --- Help
  static bool _matchesHelpPatterns(String q) {
    final patterns = [
      'help',
      'how to',
      'what can',
      'commands',
      'features',
      'guide',
      'tutorial',
      'instructions',
    ];
    return patterns.any((p) => q.contains(p));
  }

  static QueryIntent _getHelpIntent(String q) {
    if (_containsAny(q, [
      'what can you do',
      'what features',
      'app features',
      'capabilities',
      'functions',
    ])) {
      return QueryIntent.appFeatures;
    }
    if (_containsAny(q, [
      'how to use',
      'how does this work',
      'getting started',
      'tutorial',
      'how to start',
    ])) {
      return QueryIntent.howToUse;
    }
    return QueryIntent.generalHelp;
  }

  // --- Fuzzy fallback (conservative)
  static QueryIntent _fuzzyMatchIntent(String q) {
    final intentPatterns = {
      QueryIntent.navigationAddExpense: [
        'how to add an expense',
        'add expense',
        'record expense',
        'log expense',
        'enter expense',
      ],
      QueryIntent.navigationReports: [
        'open reports',
        'view reports',
      ],
      QueryIntent.navigationProfile: [
        'open profile',
        'go to profile',
      ],
      QueryIntent.navigationHistory: [
        'open history',
        'view history',
      ],

      QueryIntent.budgetAnalysis: [
        'analyze my budget',
        'budget analysis',
        'budget breakdown',
      ],
      QueryIntent.totalSpending: [
        'total spending',
        'total spent',
        'how much did i spend',
      ],
      QueryIntent.monthlySpending: [
        'this month spending',
        'monthly spending',
        'last month spending',
      ],
      QueryIntent.weeklySpending: [
        'weekly spending',
        'this week spending',
      ],
      QueryIntent.dailySpending: [
        'today spending',
        'daily spending',
      ],
      QueryIntent.categorySpending: [
        'spending on food',
        'category spending',
        'money on category',
      ],
      QueryIntent.topExpenses: [
        'biggest expense',
        'top expenses',
      ],
      QueryIntent.recentExpenses: [
        'recent expenses',
        'latest transactions',
      ],
      QueryIntent.expenseComparison: [
        'compare spending',
        'vs last month',
      ],
      QueryIntent.searchExpenses: [
        'search expenses',
        'find expenses',
      ],
      QueryIntent.expensesByDate: [
        'expenses on date',
        'transactions on',
      ],
      QueryIntent.insights: [
        'insights',
        'spending insights',
      ],
      QueryIntent.spendingTips: [
        'spending tips',
        'save money',
      ],
      QueryIntent.generalHelp: ['help', 'what can you do'],
      QueryIntent.appFeatures: ['features', 'capabilities'],
      QueryIntent.howToUse: ['how to use', 'guide'],
      QueryIntent.profileInfo: [
        'my profile',
        'account info',
        'profile details',
      ],
    };

    int best = -1;
    QueryIntent bestIntent = QueryIntent.unknown;
    for (final entry in intentPatterns.entries) {
      for (final pattern in entry.value) {
        final score = _similarityScore(q, pattern);
        if (score > best) {
          best = score;
          bestIntent = entry.key;
        }
      }
    }
    if (best >= 65) {
      print('Fuzzy matched: $bestIntent (score $best)');
      return bestIntent;
    }
    return QueryIntent.unknown;
  }

  // --- Helpers used by response_generator.dart
  static String? extractSearchTerm(String query) {
    // Supports: "search for X", "find X", "look for X", "show me X",
    // "expenses with X", "transactions containing X"
    final regs = [
      RegExp(r'search for (.+)', caseSensitive: false),
      RegExp(r'find (.+)', caseSensitive: false),
      RegExp(r'look for (.+)', caseSensitive: false),
      RegExp(r'show me (.+)', caseSensitive: false),
      RegExp(r'expenses with (.+)', caseSensitive: false),
      RegExp(
        r'transactions containing (.+)',
        caseSensitive: false,
      ),
    ];
    final q = query.trim();
    for (final r in regs) {
      final m = r.firstMatch(q);
      if (m != null && m.group(1) != null) {
        return m.group(1)!.trim();
      }
    }
    return null;
  }

  // Levenshtein-based similarity -> 0..100
  static int _similarityScore(String s, String t) {
    if (s == t) return 100;
    if (s.isEmpty || t.isEmpty) return 0;
    final m = s.length, n = t.length;
    final dp = List.generate(
      m + 1,
      (_) => List<int>.filled(n + 1, 0),
    );
    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost =
            s.codeUnitAt(i - 1) == t.codeUnitAt(j - 1)
                ? 0
                : 1;
        dp[i][j] = min(
          dp[i - 1][j] + 1,
          min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
        );
      }
    }
    return 100 - (dp[m][n] * 100 ~/ (m + n));
  }

  static bool _containsAny(
    String text,
    List<String> patterns,
  ) {
    return patterns.any((p) => text.contains(p));
  }
}
