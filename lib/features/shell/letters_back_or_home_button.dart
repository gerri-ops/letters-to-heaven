import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Back when the stack allows it; otherwise Home so the user is never stuck.
class LettersBackOrHomeButton extends StatelessWidget {
  const LettersBackOrHomeButton({
    super.key,
    this.fallbackLocation = '/shell/home',
  });

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    return IconButton(
      icon: Icon(canPop ? Icons.arrow_back : Icons.home_outlined),
      tooltip: canPop ? 'Back' : 'Home',
      onPressed: () {
        if (canPop) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
    );
  }
}
