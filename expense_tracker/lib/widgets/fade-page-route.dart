// lib/widgets/fade_page_route.dart
import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;

  FadePageRoute({required this.child})
    : super(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                child,
        transitionDuration: const Duration(
          milliseconds: 300,
        ),
        reverseTransitionDuration: const Duration(
          milliseconds: 300,
        ),
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      );
}
