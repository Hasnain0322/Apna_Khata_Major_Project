// lib/services/query_intent.dart
import 'dart:math';

enum QueryIntent {
  navigationAddExpense,
  navigationReports,
  navigationProfile,
  navigationHistory,
  totalSpending,
  categorySpending,
  topExpenses,
  recentExpenses,
  monthlySpending,
  weeklySpending,
  dailySpending,
  expenseComparison,
  searchExpenses,
  expensesByDate,
  profileInfo,
  insights,
  spendingTips,
  budgetAnalysis,
  generalHelp,
  appFeatures,
  howToUse,
  unknown,
}

class QueryClassifier {
  static QueryIntent classifyQuery(String query) {
    final lowerQuery = query.toLowerCase().trim();
    print('Classifying query: $lowerQuery');

    if (_matchesNavigationPatterns(lowerQuery)) {
      return _getNavigationIntent(lowerQuery);
    }
    if (_matchesSpendingPatterns(lowerQuery)) {
      return _getSpendingIntent(lowerQuery);
    }
    if (_matchesSearchPatterns(lowerQuery)) {
      return _getSearchIntent(lowerQuery);
    }
    if (_matchesProfilePatterns(lowerQuery)) {
      return QueryIntent.profileInfo;
    }
    if (_matchesInsightPatterns(lowerQuery)) {
      return _getInsightIntent(lowerQuery);
    }
    if (_matchesHelpPatterns(lowerQuery)) {
      return _getHelpIntent(lowerQuery);
    }

    return _fuzzyMatchIntent(lowerQuery);
  }

  static bool _matchesNavigationPatterns(String query) {
    final patterns = [
      'add',
      'create',
      'new',
      'record',
      'log',
      'enter',
      'input',
      'how to add',
      'add new',
      'insert',
      'track new',
      'report',
      'analysis',
      'analytics',
      'chart',
      'graph',
      'visual',
      'summary',
      'overview',
      'insights',
      'statistics',
      'show reports',
      'view reports',
      'financial report',
      'see reports',
      'profile',
      'account',
      'settings',
      'personal info',
      'my info',
      'user info',
      'edit profile',
      'change password',
      'my account',
      'history',
      'all expenses',
      'transactions',
      'expense list',
      'view all',
      'see all',
      'complete list',
      'full history',
      'transaction history',
      'navigate',
      'go to',
      'open',
      'show me',
      'take me to',
      'go',
      'move to',
    ];
    return patterns.any((p) => query.contains(p));
  }

  static QueryIntent _getNavigationIntent(String query) {
    if (_fuzzyContains(query, [
      'add expense',
      'new expense',
      'create expense',
      'record expense',
      'log expense',
      'enter expense',
      'input expense',
      'add transaction',
      'new transaction',
      'how to add',
      'how do i add',
      'add new expense',
      'track expense',
      'insert expense',
      'log new spend',
    ])) {
      return QueryIntent.navigationAddExpense;
    }
    if (_fuzzyContains(query, [
      'report',
      'analysis',
      'analytics',
      'chart',
      'graph',
      'visual',
      'breakdown',
      'summary',
      'overview',
      'insights',
      'statistics',
      'show reports',
      'view reports',
      'financial report',
      'see reports',
      'reports page',
      'view analytics',
      'spending report',
    ])) {
      return QueryIntent.navigationReports;
    }
    if (_fuzzyContains(query, [
      'profile',
      'account',
      'settings',
      'personal info',
      'my info',
      'user info',
      'edit profile',
      'change password',
      'account settings',
      'my profile',
      'user details',
      'personal settings',
    ])) {
      return QueryIntent.navigationProfile;
    }
    if (_fuzzyContains(query, [
      'history',
      'all expenses',
      'transactions',
      'expense list',
      'view all',
      'see all',
      'complete list',
      'full history',
      'transaction history',
      'expense history',
      'past expenses',
      'old spends',
      'previous transactions',
    ])) {
      return QueryIntent.navigationHistory;
    }
    return QueryIntent.unknown;
  }

  static bool _matchesSpendingPatterns(String query) {
    final patterns = [
      'spent',
      'spend',
      'spending',
      'money',
      'cost',
      'expense',
      'total',
      'amount',
      'sum',
      'budget',
      'financial',
      'price',
      'paid',
      'how much',
      'what did i spend',
      'my spending',
      'costs',
      'expenditure',
      'outgoings',
      'how much did i',
      'total cost',
      'what is my',
    ];
    return patterns.any((p) => query.contains(p));
  }

  static QueryIntent _getSpendingIntent(String query) {
    if (_fuzzyContains(query, [
      'total spent',
      'how much spent',
      'total spending',
      'overall spending',
      'total expense',
      'total amount',
      'sum of expenses',
      'all expenses',
      'total money',
      'overall cost',
      'total costs',
      'grand total',
      'how much have i spent',
      'my total spending',
    ])) {
      return QueryIntent.totalSpending;
    }
    if (_fuzzyContains(query, [
          'spent on',
          'spending on',
          'money on',
          'category',
          'type of expense',
          'food expense',
          'transport cost',
          'shopping expense',
          'bill payment',
          'expenses in category',
          'category total',
          'cost on',
          'amount for',
        ]) ||
        _containsCategoryNames(query)) {
      return QueryIntent.categorySpending;
    }
    if (_fuzzyContains(query, [
      'biggest expense',
      'largest expense',
      'highest expense',
      'top expense',
      'most expensive',
      'maximum expense',
      'costliest',
      'major expenses',
      'big purchases',
      'expensive items',
      'top spends',
      'biggest spend',
    ])) {
      return QueryIntent.topExpenses;
    }
    if (_fuzzyContains(query, [
      'recent expense',
      'latest expense',
      'last expense',
      'new expense',
      'recent transaction',
      'latest transaction',
      'recent spending',
      'what did i buy',
      'recent purchases',
      'last few expenses',
      'latest spends',
    ])) {
      return QueryIntent.recentExpenses;
    }
    if (_fuzzyContains(query, [
      'this month',
      'current month',
      'monthly',
      'last month',
      'previous month',
      'month wise',
      'per month',
      'monthly expense',
      'monthly spending',
      'month total',
      'spending this month',
    ])) {
      return QueryIntent.monthlySpending;
    }
    if (_fuzzyContains(query, [
      'this week',
      'current week',
      'weekly',
      'last week',
      'previous week',
      'week wise',
      'per week',
      'weekly expense',
      'weekly spending',
      'week total',
    ])) {
      return QueryIntent.weeklySpending;
    }
    if (_fuzzyContains(query, [
      'today',
      'daily',
      'per day',
      'this day',
      'yesterday',
      'day wise',
      'daily expense',
      'daily spending',
      'today total',
      'daily total',
      'todays spending',
    ])) {
      return QueryIntent.dailySpending;
    }
    if (_fuzzyContains(query, [
      'compare',
      'comparison',
      'vs',
      'versus',
      'difference between',
      'more than',
      'less than',
      'increase',
      'decrease',
      'trend',
      'compare months',
    ])) {
      return QueryIntent.expenseComparison;
    }
    return QueryIntent.totalSpending;
  }

  static bool _matchesSearchPatterns(String query) {
    final patterns = [
      'search',
      'find',
      'look for',
      'show me',
      'filter',
      'where is',
      'when did i',
      'did i buy',
      'have i paid',
      'expenses with',
      'transactions containing',
      'look up',
      'query for',
    ];
    return patterns.any((p) => query.contains(p));
  }

  static QueryIntent _getSearchIntent(String query) {
    if (_fuzzyContains(query, [
      'search expense',
      'find expense',
      'look for expense',
      'search transaction',
      'find transaction',
      'search item',
      'find item',
      'expenses with',
      'transactions containing',
    ])) {
      return QueryIntent.searchExpenses;
    }
    if (_fuzzyContains(query, [
      'expenses on',
      'spending on date',
      'expenses by date',
      'on this date',
      'expenses for',
      'transactions on',
      'spending on',
    ])) {
      return QueryIntent.expensesByDate;
    }
    return QueryIntent.searchExpenses;
  }

  static bool _matchesProfilePatterns(String query) {
    final patterns = [
      'my profile',
      'who am i',
      'account info',
      'my info',
      'user info',
      'my details',
      'personal info',
      'my account',
      'profile details',
      'account details',
    ];
    return patterns.any((p) => query.contains(p));
  }

  static bool _matchesInsightPatterns(String query) {
    final patterns = [
      'insights',
      'analyze',
      'smart',
      'tips',
      'advice',
      'suggestions',
      'budget',
      'save money',
      'financial advice',
      'spending patterns',
      'spending insights',
      'analyze my spending',
      'give me tips',
      'how to save',
      'budget help',
      'money saving',
      'financial tips',
    ];
    return patterns.any((p) => query.contains(p));
  }

  static QueryIntent _getInsightIntent(String query) {
    if (_fuzzyContains(query, [
      'insights',
      'analyze my spending',
      'spending insights',
      'financial insights',
      'smart insights',
      'show insights',
      'my insights',
      'give insights',
    ])) {
      return QueryIntent.insights;
    }
    if (_fuzzyContains(query, [
      'spending tips',
      'save money',
      'budget tips',
      'financial tips',
      'money advice',
      'how to save',
      'saving tips',
      'tips to save',
    ])) {
      return QueryIntent.spendingTips;
    }
    if (_fuzzyContains(query, [
      'budget analysis',
      'budget breakdown',
      'analyze budget',
      'budget insights',
      'financial analysis',
      'analyze my budget',
    ])) {
      return QueryIntent.budgetAnalysis;
    }
    return QueryIntent.insights;
  }

  static bool _matchesHelpPatterns(String query) {
    final patterns = [
      'help',
      'how to',
      'what can',
      'commands',
      'features',
      'guide',
      'tutorial',
      'instructions',
      'assist',
      'support',
      'what do you do',
      'how does this work',
      'app guide',
      'assist me',
    ];
    return patterns.any((p) => query.contains(p));
  }

  static QueryIntent _getHelpIntent(String query) {
    if (_fuzzyContains(query, [
      'what can you do',
      'what features',
      'app features',
      'capabilities',
      'what is possible',
      'functions',
      'app capabilities',
    ])) {
      return QueryIntent.appFeatures;
    }
    if (_fuzzyContains(query, [
      'how to use',
      'how does this work',
      'getting started',
      'tutorial',
      'guide',
      'instructions',
      'how to start',
    ])) {
      return QueryIntent.howToUse;
    }
    return QueryIntent.generalHelp;
  }

  static QueryIntent _fuzzyMatchIntent(String query) {
    final intentPatterns = {
      QueryIntent.navigationAddExpense: [
        'add expense',
        'new expense',
        'create expense',
        'record expense',
      ],
      QueryIntent.navigationReports: [
        'reports',
        'analysis',
        'charts',
        'summary',
      ],
      QueryIntent.navigationProfile: [
        'profile',
        'account',
        'settings',
      ],
      QueryIntent.navigationHistory: [
        'history',
        'expenses list',
        'transactions',
      ],
      QueryIntent.totalSpending: [
        'total spent',
        'how much spent',
        'total spending',
      ],
      QueryIntent.categorySpending: [
        'spent on',
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
      QueryIntent.monthlySpending: [
        'monthly spending',
        'this month spent',
      ],
      QueryIntent.weeklySpending: [
        'weekly spending',
        'this week spent',
      ],
      QueryIntent.dailySpending: [
        'daily spending',
        'today spent',
      ],
      QueryIntent.expenseComparison: [
        'compare spending',
        'vs last month',
      ],
      QueryIntent.searchExpenses: [
        'search for',
        'find expense',
      ],
      QueryIntent.expensesByDate: [
        'expenses on date',
        'spending on',
      ],
      QueryIntent.profileInfo: [
        'my profile',
        'account info',
      ],
      QueryIntent.insights: [
        'insights',
        'analyze spending',
      ],
      QueryIntent.spendingTips: [
        'spending tips',
        'save money',
      ],
      QueryIntent.budgetAnalysis: [
        'budget analysis',
        'financial analysis',
      ],
      QueryIntent.generalHelp: ['help', 'what can you do'],
      QueryIntent.appFeatures: ['features', 'capabilities'],
      QueryIntent.howToUse: ['how to use', 'guide'],
    };

    int maxScore = 0;
    QueryIntent bestIntent = QueryIntent.unknown;

    intentPatterns.forEach((intent, patterns) {
      for (final pattern in patterns) {
        final score = _levenshteinDistance(query, pattern);
        if (score > maxScore) {
          maxScore = score;
          bestIntent = intent;
        }
      }
    });

    if (maxScore > query.length * 0.4) {
      print(
        'Fuzzy matched to: $bestIntent with score $maxScore',
      );
      return bestIntent;
    }

    print('No match found, falling back to unknown');
    return QueryIntent.unknown;
  }

  static int _levenshteinDistance(String s, String t) {
    if (s == t) return 100;
    if (s.isEmpty || t.isEmpty) return 0;

    final m = s.length;
    final n = t.length;
    final dp = List.generate(
      m + 1,
      (_) => List<int>.filled(n + 1, 0),
    );

    for (int i = 0; i <= m; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= n; j++) {
      dp[0][j] = j;
    }

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        dp[i][j] = min(
          dp[i - 1][j] + 1,
          min(dp[i][j - 1] + 1, dp[i - 1][j - 1] + cost),
        );
      }
    }

    return 100 - (dp[m][n] * 100 ~/ (m + n));
  }

  static bool _fuzzyContains(
    String query,
    List<String> patterns,
  ) {
    for (final pattern in patterns) {
      if (_levenshteinDistance(query, pattern) > 40) {
        return true;
      }
    }
    return false;
  }

  static bool _containsCategoryNames(String query) {
    final categories = [
      'food',
      'transport',
      'travel',
      'entertainment',
      'shopping',
      'bills',
      'health',
      'education',
      'groceries',
      'restaurant',
      'fuel',
      'rent',
      'utilities',
      'clothing',
      'electronics',
      'sports',
      'beauty',
      'gifts',
      'investment',
      'subscription',
    ];
    return categories.any(
      (category) => query.contains(category),
    );
  }

  static String? extractCategoryFromQuery(String query) {
    final categoryMap = {
      'food': [
        'food',
        'dining',
        'restaurant',
        'meal',
        'lunch',
        'dinner',
        'breakfast',
        'eat',
        'hungry',
      ],
      'groceries': [
        'groceries',
        'grocery',
        'supermarket',
        'vegetables',
        'fruits',
        'shopping',
      ],
      'transport': [
        'transport',
        'transportation',
        'travel',
        'commute',
        'bus',
        'train',
        'car',
      ],
      'fuel': ['fuel', 'gas', 'petrol', 'diesel'],
      'bills': [
        'bills',
        'utilities',
        'electricity',
        'water',
        'internet',
        'phone',
        'payment',
      ],
      'rent': [
        'rent',
        'mortgage',
        'housing',
        'apartment',
        'house',
      ],
      'shopping': [
        'shopping',
        'clothes',
        'clothing',
        'fashion',
        'accessories',
        'buy',
      ],
      'entertainment': [
        'entertainment',
        'movie',
        'cinema',
        'game',
        'fun',
        'leisure',
      ],
      'health': [
        'health',
        'medical',
        'doctor',
        'pharmacy',
        'medicine',
        'hospital',
      ],
      'education': [
        'education',
        'course',
        'book',
        'learning',
        'school',
        'study',
      ],
      'fitness': [
        'fitness',
        'gym',
        'sports',
        'exercise',
        'workout',
      ],
      'beauty': [
        'beauty',
        'cosmetics',
        'salon',
        'personal care',
        'hair',
      ],
    };

    final lowerQuery = query.toLowerCase();

    for (final entry in categoryMap.entries) {
      if (entry.value.any(
        (keyword) => lowerQuery.contains(keyword),
      )) {
        return entry.key;
      }
    }

    return null;
  }

  static String? extractSearchTerm(String query) {
    final searchPatterns = [
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

    for (final pattern in searchPatterns) {
      final match = pattern.firstMatch(query);
      if (match != null && match.group(1) != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }
}
