// chatbot_widget.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:expense_tracker/animations/animation_text_widget.dart';
import 'package:expense_tracker/animations/typing_indicator.dart';

class ChatbotWidget extends StatefulWidget {
  const ChatbotWidget({super.key});

  @override
  _ChatbotWidgetState createState() =>
      _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
  bool _isBotTyping = false;

  // NEW: State to hold recommended questions
  List<String> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _addInitialMessage();
  }

  // --- Main handler for submitting text ---
  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;
    _textController.clear();

    // Add user's message and clear old recommendations
    setState(() {
      _messages.add({'isUser': true, 'message': text});
      _isBotTyping = true;
      _recommendations =
          []; // Clear previous recommendations
    });
    _scrollToBottom();

    // Get response and new recommendations from the backend
    final botReplyData = await _getBotResponse(text);

    setState(() {
      _isBotTyping = false;
      _messages.add({
        'isUser': false,
        'message': botReplyData['response'],
      });
      // Set the new recommendations
      _recommendations = List<String>.from(
        botReplyData['recommendations'] ?? [],
      );
    });
    _scrollToBottom();
  }

  // --- UPDATED: API call now returns a Map ---
  Future<Map<String, dynamic>> _getBotResponse(
    String message,
  ) async {
    try {
      const String apiUrl =
          'http://192.168.31.169:5000/predict'; // Replace with your IP
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message': message}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'response': "Sorry, an error occurred.",
          'recommendations': [],
        };
      }
    } catch (e) {
      return {
        'response':
            "I can't connect to my brain right now.",
        'recommendations': [],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount:
                _messages.length + (_isBotTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length &&
                  _isBotTyping) {
                return const TypingIndicator();
              }
              final message = _messages[index];
              return _buildChatMessage(message);
            },
          ),
        ),
        // NEW: Display recommended questions
        if (_recommendations.isNotEmpty)
          _buildRecommendations(),
        _buildTextComposer(),
      ],
    );
  }

  // --- NEW: Widget to display recommendations ---
  Widget _buildRecommendations() {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 4.0,
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 4.0,
        children:
            _recommendations.map((text) {
              return ActionChip(
                label: Text(text),
                onPressed: () {
                  _handleSubmitted(text);
                },
              );
            }).toList(),
      ),
    );
  }

  // Other widgets (_buildTextComposer, _buildChatMessage, etc.) remain largely the same...
  // You can copy them from your existing file.
  // Minor changes are included here for completeness.

  void _addInitialMessage() {
    setState(() {
      _messages.add({
        'isUser': false,
        'message': "Hello! Ask me anything about the app.",
      });
    });
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8.0,
        vertical: 8.0,
      ),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              onSubmitted: _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: "Send a message",
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed:
                () =>
                    _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message) {
    final bool isUserMessage = message['isUser'];
    final bool isLastMessage = _messages.last == message;

    return Align(
      alignment:
          isUserMessage
              ? Alignment.centerRight
              : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(
          vertical: 5.0,
          horizontal: 8.0,
        ),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color:
              isUserMessage
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child:
            !isUserMessage && isLastMessage
                ? AnimatedTextWidget(
                  text: message['message'],
                  textStyle: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodyLarge?.color,
                  ),
                  onFinished:
                      () {}, // Recommendations appear after this
                )
                : Text(
                  message['message'],
                  style: TextStyle(
                    color:
                        isUserMessage
                            ? Colors.white
                            : Theme.of(
                              context,
                            ).textTheme.bodyLarge?.color,
                  ),
                ),
      ),
    );
  }
}
