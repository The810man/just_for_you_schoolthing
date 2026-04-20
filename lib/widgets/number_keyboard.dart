import 'package:flutter/material.dart';

class NumberKeyboard extends StatelessWidget {
  final void Function(String key) onKey;
  final bool allowNegative;
  final bool allowDecimal;

  const NumberKeyboard({
    super.key,
    required this.onKey,
    this.allowNegative = true,
    this.allowDecimal = true,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      [allowNegative ? '±' : '', '0', allowDecimal ? ',' : ''],
    ];

    return Column(
      children: [
        ...keys.map((row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: row.map((k) {
                  if (k.isEmpty) return const Expanded(child: SizedBox());
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _KeyButton(label: k, onTap: () => onKey(k)),
                    ),
                  );
                }).toList(),
              ),
            )),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _KeyButton(
                    label: '⌫',
                    onTap: () => onKey('⌫'),
                    color: Colors.orange.shade100,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _KeyButton(
                    label: 'C',
                    onTap: () => onKey('C'),
                    color: Colors.red.shade100,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _KeyButton({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
      ),
      child: Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}
