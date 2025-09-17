// lib/services/chatbot_service.dart
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/models/user_profile_model.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/proactive_insights.dart';
import 'package:expense_tracker/services/query_intent.dart';
import 'package:expense_tracker/services/response_generator.dart';

class ChatbotService {
  final FirestoreService _firestoreService =
      FirestoreService();

  Future<ChatResponse> processQuery(
    String userQuery,
  ) async {
    try {
      final intent = QueryClassifier.classifyQuery(
        userQuery,
      );
      print('Detected intent: $intent');

      final expenses =
          await _firestoreService.getExpensesStream().first;
      final userProfile =
          await _firestoreService.getUserProfile().first;

      return ResponseGenerator.generateResponse(
        intent,
        expenses,
        userProfile,
        userQuery,
      );
    } catch (e) {
      print('Error in processQuery: $e');
      return ResponseGenerator.generateResponse(
        QueryIntent.unknown,
        const <Expense>[],
        null,
        userQuery,
      );
    }
  }

  List<QuickAction> getSuggestedQueries() {
    return [
      QuickAction(
        label: 'Monthly spending',
        type: QuickActionType.query,
        data: 'How much did I spend this month?',
      ),
      QuickAction(
        label: 'Recent expenses',
        type: QuickActionType.query,
        data: 'Show my recent expenses',
      ),
      QuickAction(
        label: 'Budget analysis',
        type: QuickActionType.query,
        data: 'Analyze my budget',
      ),
      QuickAction(
        label: 'Forecast spending',
        type: QuickActionType.query,
        data: 'Forecast my spending',
      ),
      QuickAction(
        label: 'Subscriptions',
        type: QuickActionType.query,
        data: 'Show my subscriptions',
      ),
      QuickAction(
        label: 'Average per day',
        type: QuickActionType.query,
        data: 'What is my average per day?',
      ),
      QuickAction(
        label: 'Open Reports',
        type: QuickActionType.navigation,
        data: 'reports',
      ),
    ];
  }

  bool isNavigationQuery(String query) {
    final intent = QueryClassifier.classifyQuery(query);
    return [
      QueryIntent.navigationAddExpense,
      QueryIntent.navigationReports,
      QueryIntent.navigationProfile,
      QueryIntent.navigationHistory,
    ].contains(intent);
  }

  NavigationAction? getNavigationAction(String query) {
    final intent = QueryClassifier.classifyQuery(query);
    switch (intent) {
      case QueryIntent.navigationAddExpense:
        return NavigationAction.addExpense;
      case QueryIntent.navigationReports:
        return NavigationAction.reports;
      case QueryIntent.navigationProfile:
        return NavigationAction.profile;
      case QueryIntent.navigationHistory:
        return NavigationAction.history;
      default:
        return null;
    }
  }

  Future<ChatResponse> getWelcomeMessage(
    UserProfile? userProfile,
  ) async {
    final userName = userProfile?.displayName ?? 'there';
    final expenses =
        await _firestoreService.getExpensesStream().first;
    final insights = ProactiveInsights.generateInsights(
      expenses,
    );

    String msg = 'Hi $userName! 👋\n\n';
    if (insights.isNotEmpty) {
      final first = insights.first;
      msg += '${first.title}\n${first.message}\n\n';
    }
    msg +=
        'Ask for a spending summary, a budget analysis, subscriptions, or a forecast.';

    return ChatResponse(
      message: msg,
      quickActions: getSuggestedQueries(),
    );
  }

  Future<ChatResponse> processQuickAction(
    String action,
  ) async {
    return processQuery(action);
  }
}

enum NavigationAction {
  addExpense,
  reports,
  profile,
  history,
}
