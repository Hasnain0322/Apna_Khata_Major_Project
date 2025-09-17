// lib/screens/chat_screen.dart

import 'package:expense_tracker/widgets/fade-page-route.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/chatbot_service.dart';
import 'package:expense_tracker/services/firestore_service.dart';
import 'package:expense_tracker/services/response_generator.dart';
import 'package:expense_tracker/utils/app_theme.dart';
import 'package:expense_tracker/widgets/fade-page-route.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/expenses_screen.dart';
import 'package:expense_tracker/screens/profile_screen.dart';
import 'package:expense_tracker/screens/reports_screen.dart';

class ChatboxBottomSheet extends StatefulWidget {
  final FirestoreService firestoreService;

  const ChatboxBottomSheet({
    super.key,
    required this.firestoreService,
  });

  @override
  State<ChatboxBottomSheet> createState() =>
      _ChatboxBottomSheetState();
}

class _ChatboxBottomSheetState
    extends State<ChatboxBottomSheet> {
  final TextEditingController _messageController =
      TextEditingController();
  final List<ChatMessage> _messages = [];
  final ChatbotService _chatbotService = ChatbotService();
  final ScrollController _scrollController =
      ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() async {
    try {
      final userProfile =
          await widget.firestoreService
              .getUserProfile()
              .first;
      final welcomeResponse = await _chatbotService
          .getWelcomeMessage(userProfile);
      setState(() {
        _messages.add(
          ChatMessage(
            text: welcomeResponse.message,
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: welcomeResponse.quickActions,
          ),
        );
      });
    } catch (e) {
      final welcomeResponse = await _chatbotService
          .getWelcomeMessage(null);
      setState(() {
        _messages.add(
          ChatMessage(
            text: welcomeResponse.message,
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: welcomeResponse.quickActions,
          ),
        );
      });
    }
  }

  void _sendMessage({String? customMessage}) async {
    final userMessage =
        customMessage ?? _messageController.text.trim();
    if (userMessage.isEmpty) return;

    if (customMessage == null) {
      _messageController.clear();
    }

    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _chatbotService.processQuery(
        userMessage,
      );

      setState(() {
        _messages.add(
          ChatMessage(
            text: response.message,
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: response.quickActions,
          ),
        );
        _isLoading = false;
      });

      // IMPORTANT: Do NOT auto-navigate here anymore.
      // Navigation should only occur when the user taps a quick action.
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                'Sorry, I encountered an issue. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: [
              QuickAction(
                label: 'Try Again',
                type: QuickActionType.query,
                data: 'Help',
              ),
              QuickAction(
                label: 'Help',
                type: QuickActionType.query,
                data: 'Help',
              ),
            ],
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _handleQuickAction(QuickAction action) async {
    switch (action.type) {
      case QuickActionType.navigation:
        _handleDirectNavigation(action.data!);
        break;
      case QuickActionType.query:
        _sendMessage(customMessage: action.data!);
        break;
      case QuickActionType.action:
        _handleSpecialAction(action.data!);
        break;
    }
  }

  void _handleDirectNavigation(String action) {
    Navigator.of(context).pop(); // Close chat first

    switch (action.toLowerCase()) {
      case 'add_expense':
        Navigator.of(context).push(
          FadePageRoute(child: const AddExpenseScreen()),
        );
        break;
      case 'reports':
        Navigator.of(
          context,
        ).push(FadePageRoute(child: const ReportsScreen()));
        break;
      case 'profile':
        Navigator.of(
          context,
        ).push(FadePageRoute(child: const ProfileScreen()));
        break;
      case 'expenses':
      case 'history':
        Navigator.of(context).push(
          FadePageRoute(child: const ExpensesScreen()),
        );
        break;
    }
  }

  void _handleSpecialAction(String action) {
    _sendMessage(customMessage: action);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        Theme.of(context).extension<AppTokens>()!;
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.secondaryText.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tokens.primaryAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow:
                        theme
                            .extension<AppShadows>()!
                            .cardShadow,
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: tokens.primaryText,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Assistant',
                        style: theme.textTheme.titleLarge,
                      ),
                      Text(
                        'Your smart expense companion',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed:
                      () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close,
                    color: tokens.iconColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: tokens.secondaryText.withOpacity(0.1),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(
                  _messages[index],
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tokens.cardBackground,
              boxShadow:
                  theme.extension<AppShadows>()!.cardShadow,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.onSurface
                      .withOpacity(0.06),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText:
                            'Ask me anything about your expenses...',
                        hintStyle: theme
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: tokens.secondaryText,
                            ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: tokens.background,
                        contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textInputAction: TextInputAction.send,
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: tokens.primaryAccent,
                      borderRadius: BorderRadius.circular(
                        24,
                      ),
                      boxShadow:
                          theme
                              .extension<AppShadows>()!
                              .cardShadow,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(
                        Icons.send,
                        color: tokens.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final tokens =
        Theme.of(context).extension<AppTokens>()!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment:
            message.isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                message.isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tokens.primaryAccent,
                    shape: BoxShape.circle,
                    boxShadow:
                        theme
                            .extension<AppShadows>()!
                            .cardShadow,
                  ),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 16,
                    color: tokens.primaryText,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color:
                        message.isUser
                            ? tokens.primaryAccent
                            : tokens.cardBackground,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow:
                        theme
                            .extension<AppShadows>()!
                            .cardShadow,
                  ),
                  child: Text(
                    message.text,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(
                          color: tokens.primaryText,
                        ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tokens.iconColor.withOpacity(
                      0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 16,
                    color: tokens.iconColor,
                  ),
                ),
              ],
            ],
          ),
          if (message.quickActions.isNotEmpty &&
              !message.isUser) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    message.quickActions.map((action) {
                      return InkWell(
                        onTap:
                            () =>
                                _handleQuickAction(action),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                          decoration: BoxDecoration(
                            color: tokens.primaryAccent
                                .withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: tokens.primaryAccent
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            action.label,
                            style: theme
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: tokens.primaryText,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final tokens =
        Theme.of(context).extension<AppTokens>()!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: tokens.primaryAccent,
              shape: BoxShape.circle,
              boxShadow:
                  theme.extension<AppShadows>()!.cardShadow,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 16,
              color: tokens.primaryText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: tokens.cardBackground,
              borderRadius: BorderRadius.circular(18),
              boxShadow:
                  theme.extension<AppShadows>()!.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI is thinking',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                          tokens.primaryAccent,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<QuickAction> quickActions;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions = const [],
  });
}
