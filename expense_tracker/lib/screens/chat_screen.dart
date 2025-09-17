// lib/screens/chat_screen.dart

import 'dart:async';
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

  // Loader that shows a “thinking” bubble at the end of the list
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

  Future<void> _sendMessage({String? customMessage}) async {
    final userMessage =
        customMessage ?? _messageController.text.trim();
    if (userMessage.isEmpty) return;

    if (customMessage == null) {
      _messageController.clear();
    }

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true; // show thinking bubble
    });

    _scrollToBottom();

    try {
      final response = await _chatbotService.processQuery(
        userMessage,
      );

      // Keep loader visible for a minimum delay to feel natural
      await Future.delayed(
        const Duration(milliseconds: 600),
      );

      // Remove loader and show a typing message that reveals text progressively
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text: '',
            isUser: false,
            timestamp: DateTime.now(),
            quickActions: response.quickActions,
            isTypingText: true,
            fullText: response.message,
            typingSpeedMs: _pickTypingSpeed(
              response.message,
            ),
          ),
        );
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            text:
                'Sorry, there was an issue. Please try again.',
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
      });
    }

    _scrollToBottom();
  }

  // Choose a reasonable typing speed based on length (slower for longer text)
  int _pickTypingSpeed(String text) {
    final len = text.length;
    if (len <= 80) return 15;
    if (len <= 200) return 10;
    return 6;
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.secondaryText.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount:
                  _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading &&
                    index == _messages.length) {
                  return _buildThinkingIndicator(); // Loader row at the end
                }
                return _buildMessageBubble(
                  _messages[index],
                  index,
                );
              },
            ),
          ),

          // Input
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

  // Thinking indicator row (shows while awaiting response)
  Widget _buildThinkingIndicator() {
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
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: _DotSpinner(stroke: 2),
                ),
                const SizedBox(width: 4),
                const _AnimatedDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Message bubble with optional typewriter animation
  Widget _buildMessageBubble(
    ChatMessage message,
    int index,
  ) {
    final tokens =
        Theme.of(context).extension<AppTokens>()!;
    final theme = Theme.of(context);

    final bubble = Container(
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
            theme.extension<AppShadows>()!.cardShadow,
      ),
      child:
          message.isUser
              ? Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.primaryText,
                ),
              )
              : (message.isTypingText &&
                  message.fullText != null)
              ? _TypewriterText(
                fullText: message.fullText!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.primaryText,
                ),
                speed: Duration(
                  milliseconds: message.typingSpeedMs,
                ),
                onComplete: () {
                  // Replace typing message with final message text so chips can appear
                  if (!mounted) return;
                  setState(() {
                    _messages[index] = ChatMessage(
                      text: message.fullText!,
                      isUser: false,
                      timestamp: message.timestamp,
                      quickActions: message.quickActions,
                    );
                  });
                  _scrollToBottom();
                },
              )
              : Text(
                message.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: tokens.primaryText,
                ),
              ),
    );

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
              Flexible(child: bubble),
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

          // Quick actions only after typing has finished (i.e., not during isTypingText)
          if (message.quickActions.isNotEmpty &&
              !message.isUser &&
              !message.isTypingText) ...[
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

// ==== Models for chat messages with typing ====

class ChatMessage {
  final bool isUser;
  final DateTime timestamp;

  // Rendered text (used for user and finalized bot messages)
  final String text;

  // Optional quick actions (shown only when bot message typing is complete)
  final List<QuickAction> quickActions;

  // Typing animation fields (for bot messages)
  final bool isTypingText;
  final String? fullText;
  final int typingSpeedMs;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions = const [],
    this.isTypingText = false,
    this.fullText,
    this.typingSpeedMs = 12,
  });
}

// ==== Typing animations ====

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() =>
      _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(
      vsync: this,
    );
    _timer = Timer.periodic(
      const Duration(milliseconds: 450),
      (_) {
        setState(() {
          _count = (_count + 1) % 4; // 0..3
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '.' * _count,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _DotSpinner extends StatefulWidget {
  final double stroke;
  const _DotSpinner({this.stroke = 2});

  @override
  State<_DotSpinner> createState() => _DotSpinnerState();
}

class _DotSpinnerState extends State<_DotSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        return CustomPaint(
          painter: _SpinnerPainter(
            progress: _c.value,
            color:
                Theme.of(
                  context,
                ).extension<AppTokens>()!.primaryAccent,
          ),
        );
      },
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SpinnerPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    final radius = size.width / 2;
    final start = progress * 6.28318; // 2*pi
    final sweep = 6.28318 * 0.25;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(radius, radius),
        radius: radius,
      ),
      start,
      sweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _SpinnerPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color;
  }
}

// Progressive typewriter text for bot messages
class _TypewriterText extends StatefulWidget {
  final String fullText;
  final TextStyle? style;
  final Duration speed;
  final VoidCallback? onComplete;

  const _TypewriterText({
    required this.fullText,
    this.style,
    this.speed = const Duration(milliseconds: 12),
    this.onComplete,
  });

  @override
  State<_TypewriterText> createState() =>
      _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  late String _visible;
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _visible = '';
    _start();
  }

  void _start() {
    _timer = Timer.periodic(widget.speed, (t) {
      if (!mounted) return;
      if (_i >= widget.fullText.length) {
        _timer?.cancel();
        widget.onComplete?.call();
        return;
      }
      setState(() {
        _visible += widget.fullText[_i];
        _i++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_visible, style: widget.style);
  }
}
