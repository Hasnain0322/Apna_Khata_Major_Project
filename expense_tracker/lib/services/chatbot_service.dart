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

      UserProfile? userProfile;
      userProfile =
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
        [],
        null,
        userQuery,
      );
    }
  }

  List<QuickAction> getSuggestedQueries() {
    return [
      QuickAction(
        label: 'How much did I spend this month?',
        type: QuickActionType.query,
        data: 'How much did I spend this month?',
      ),
      QuickAction(
        label: 'Show my recent expenses',
        type: QuickActionType.query,
        data: 'Show my recent expenses',
      ),
      QuickAction(
        label: 'Give me smart insights',
        type: QuickActionType.query,
        data: 'Show my insights',
      ),
      QuickAction(
        label: 'How to add an expense?',
        type: QuickActionType.query,
        data: 'How to add an expense?',
      ),
      QuickAction(
        label: 'Give me spending tips',
        type: QuickActionType.query,
        data: 'Give me spending tips',
      ),
      QuickAction(
        label: 'Analyze my budget',
        type: QuickActionType.query,
        data: 'analyze my budget',
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

    String message = 'Hi $userName! 👋\n\n';
    if (insights.isNotEmpty) {
      final topInsight = insights.first;
      message +=
          '${topInsight.title}\n${topInsight.message}\n\n';
    }
    message +=
        'I can help with spending summaries, reports, and tips.';

    return ChatResponse(
      message: message,
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
