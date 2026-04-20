import 'package:flutter/material.dart';

class CalculatorButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;

  const CalculatorButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isOperator = ['+', '-', '*', '/', '='].contains(label);
    final isClear = label == 'C';

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            backgroundColor ??
            (isOperator
                ? Theme.of(context).colorScheme.secondary
                : isClear
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primaryContainer),
        foregroundColor:
            textColor ??
            (isOperator || isClear
                ? Theme.of(context).colorScheme.onSecondary
                : Theme.of(context).colorScheme.onPrimaryContainer),
        elevation: 2,
        shadowColor: Theme.of(context).colorScheme.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        minimumSize: const Size(64, 64),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
