import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../providers/appearance_provider.dart';
import '../services/calc_service.dart';
import '../widgets/number_keyboard.dart';

/// When [isModal] is true, a "Übernehmen" button pops the navigator with the result.
class GrundrechnerScreen extends ConsumerStatefulWidget {
  final bool isModal;

  const GrundrechnerScreen({super.key, this.isModal = false});

  @override
  ConsumerState<GrundrechnerScreen> createState() => _GrundrechnerScreenState();
}

class _GrundrechnerScreenState extends ConsumerState<GrundrechnerScreen> {
  String _expression = '';
  String _display = '0';
  String? _result;

  void _onKey(String key) {
    setState(() {
      if (key == 'C') {
        _expression = '';
        _display = '0';
        _result = null;
      } else if (key == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
          _display = _expression.isEmpty ? '0' : _expression;
        }
      } else if (key == '=') {
        _calculate();
      } else if (key == ',') {
        _expression += '.';
        _display = _expression;
      } else {
        _expression += key;
        _display = _expression;
        _result = null;
      }
    });
  }

  void _addOperator(String op) {
    setState(() {
      _expression += op;
      _display = _expression;
      _result = null;
    });
  }

  void _addParenthesis(String p) {
    setState(() {
      _expression += p;
      _display = _expression;
    });
  }

  Future<void> _calculate() async {
    if (_expression.isEmpty) return;
    final res = CalcService.grundrechner(_expression);
    setState(() {
      if (res.error) {
        _display = res.values.values.first;
      } else {
        _result = res.values['Ergebnis'];
        _display = _result!;
      }
    });
    if (!res.error) {
      await ref.read(historyProvider.notifier).addEntry(
            res.historyText,
            isSideCalc: widget.isModal,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appearanceProvider);

    return Scaffold(
      backgroundColor: app.backgroundColor,
      appBar: AppBar(
        title: Text(widget.isModal ? 'Nebenrechnung' : 'Grundrechner'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: widget.isModal
            ? [
                TextButton(
                  onPressed: _result == null
                      ? null
                      : () => Navigator.pop(context, _result),
                  child: const Text('Übernehmen',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          // Display
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expression.isNotEmpty && _result != null)
                  Text(
                    _expression,
                    style: TextStyle(
                        fontSize: app.fontSize * 0.85, color: Colors.grey),
                    textAlign: TextAlign.right,
                  ),
                Text(
                  _display,
                  style: TextStyle(
                    fontSize: app.fontSize * 2,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Operator row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final op in ['(', ')', '+', '-', '*', '/', '='])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: ElevatedButton(
                        onPressed: op == '='
                            ? _calculate
                            : op == '(' || op == ')'
                                ? () => _addParenthesis(op)
                                : () => _addOperator(op),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: op == '='
                              ? const Color(0xFF1565C0)
                              : Colors.orange.shade100,
                          foregroundColor:
                              op == '=' ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(op,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Number keyboard
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NumberKeyboard(
                onKey: _onKey,
                allowNegative: false,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
