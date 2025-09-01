// animated_text_widget.dart

import 'dart:async';
import 'package:flutter/material.dart';

class AnimatedTextWidget extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final Duration speed;
  final VoidCallback onFinished;

  const AnimatedTextWidget({
    super.key,
    required this.text,
    required this.onFinished,
    this.textStyle,
    this.speed = const Duration(milliseconds: 50),
  });

  @override
  _AnimatedTextWidgetState createState() =>
      _AnimatedTextWidgetState();
}

class _AnimatedTextWidgetState
    extends State<AnimatedTextWidget> {
  String _displayedText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animateText();
  }

  @override
  void didUpdateWidget(
    covariant AnimatedTextWidget oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _timer?.cancel();
      _displayedText = '';
      _animateText();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _animateText() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (_displayedText.length < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(
            0,
            _displayedText.length + 1,
          );
        });
      } else {
        _timer?.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style:
          widget.textStyle ??
          const TextStyle(color: Colors.black),
    );
  }
}
