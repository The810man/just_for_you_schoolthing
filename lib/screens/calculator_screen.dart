import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/module.dart';
import '../services/calc_service.dart';
import '../widgets/calculator_display.dart';
import '../widgets/calculator_button.dart';

class CalculatorScreen extends StatefulWidget {
  final Module module;

  const CalculatorScreen({super.key, required this.module});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String display = '0';
  String expression = '';
  Map<String, String> formData = {};

  @override
  void initState() {
    super.initState();
    if (widget.module.ui['type'] == 'converter' ||
        widget.module.ui['type'] == 'example') {
      final widgets = widget.module.ui['layout']['widgets'] as List<dynamic>;
      for (var widget in widgets) {
        if (widget['key'] != null) {
          formData[widget['key']] = '';
        }
      }
    }
  }

  Future<String> callPython(String function, List<dynamic> args) async {
    try {
      // Temporary implementation without Chaquopy - direct Dart logic
      if (function == 'calculate') {
        final expression = args[0] as String;
        return _evaluateExpression(expression);
      } else if (function == 'convert') {
        final amount = args[0] as String;
        final from = args[1] as String;
        final to = args[2] as String;
        return _convertCurrency(amount, from, to);
      } else if (function == 'submit') {
        final name = args[0] as String;
        final age = args[1] as String;
        final fruit = args[2] as String;
        return _submitForm(name, age, fruit);
      } else if (function == 'clear') {
        return _clearForm();
      }
      return 'Error';
    } catch (e) {
      return 'Error';
    }
  }

  String _submitForm(String name, String age, String fruit) {
    if (name.isEmpty || age.isEmpty || fruit.isEmpty) {
      return "Please fill all fields";
    }
    try {
      final ageNum = int.parse(age);
      if (ageNum < 0 || ageNum > 150) {
        return "Invalid age";
      }
      return "Hello $name, you are $age years old and like $fruit!";
    } catch (e) {
      return "Invalid input";
    }
  }

  String _clearForm() {
    setState(() {
      formData.updateAll((key, value) => '');
    });
    return "Form cleared";
  }

  String _evaluateExpression(String expression) {
    try {
      final result = CalcService.grundrechner(expression);
      return result.error ? 'Error' : (result.values['Ergebnis'] ?? 'Error');
    } catch (e) {
      return 'Error';
    }
  }

  String _convertCurrency(String amount, String from, String to) {
    try {
      final rates = widget.module.ui['config']['rates'];
      final amt = double.parse(amount);
      if (from == to) return amt.toString();
      final rate = rates[from]?[to];
      if (rate != null) {
        return (amt * rate).toStringAsFixed(2);
      }
      return 'Error';
    } catch (e) {
      return 'Error';
    }
  }

  void onButtonPressed(String button) async {
    if (widget.module.ui['type'] == 'calculator') {
      if (button == 'C') {
        setState(() {
          display = '0';
          expression = '';
        });
      } else if (button == '=') {
        final result = await callPython('calculate', [expression]);
        setState(() {
          display = result;
          expression = result;
        });
      } else {
        setState(() {
          expression += button;
          display = expression;
        });
      }
    }
  }

  void onActionPressed(String action) async {
    if (action == 'convert') {
      final amount = formData['amount'] ?? '';
      final from = formData['from'] ?? '';
      final to = formData['to'] ?? '';
      if (amount.isNotEmpty && from.isNotEmpty && to.isNotEmpty) {
        final result = await callPython('convert', [amount, from, to]);
        setState(() {
          formData['result'] = result;
        });
      }
    } else if (action == 'submit') {
      final name = formData['name'] ?? '';
      final age = formData['age'] ?? '';
      final fruit = formData['fruit'] ?? '';
      final result = await callPython('submit', [name, age, fruit]);
      setState(() {
        formData['result'] = result;
      });
    } else if (action == 'clear') {
      final result = await callPython('clear', []);
      setState(() {
        formData['result'] = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.module.ui;

    if (ui['type'] == 'calculator') {
      return _buildCalculatorUI(context, ui);
    } else if (ui['type'] == 'converter' || ui['type'] == 'example') {
      return _buildConverterUI(context, ui);
    } else {
      return Scaffold(
        appBar: AppBar(title: Text(widget.module.name)),
        body: const Center(child: Text('Unsupported module type')),
      );
    }
  }

  Widget _buildCalculatorUI(BuildContext context, Map<String, dynamic> ui) {
    final buttons = ui['buttons'] as List<dynamic>;
    final gridConfig = ui['gridConfig'] ?? {};
    final maxCols = gridConfig['columns'] ?? 4;
    final childAspectRatio = (gridConfig['childAspectRatio'] ?? 1.0).toDouble();
    final spacing = (gridConfig['spacing'] ?? 12.0).toDouble();
    final padding = (gridConfig['padding'] ?? 16.0).toDouble();

    return Scaffold(
      appBar: AppBar(title: Text(widget.module.name), elevation: 0),
      body: Column(
        children: [
          CalculatorDisplay(display: display),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: _buildButtonGrid(buttons, maxCols, childAspectRatio, spacing),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonGrid(List<dynamic> buttons, int maxCols, double childAspectRatio, double spacing) {
    // Check if using new format with row/col span
    bool hasSpanInfo = false;
    for (var row in buttons) {
      if (row is List) {
        for (var item in row) {
          if (item is Map && item.containsKey('label')) {
            hasSpanInfo = true;
            break;
          }
        }
      }
    }

    if (hasSpanInfo) {
      // Use custom grid for spanning buttons
      return SingleChildScrollView(
        child: Column(
          children: buttons.map((row) {
            return Row(
              children: (row as List).map((buttonData) {
                final label = buttonData is Map ? buttonData['label'] : buttonData.toString();
                final colSpan = buttonData is Map ? (buttonData['colspan'] ?? 1) as int : 1;
                final rowSpan = buttonData is Map ? (buttonData['rowspan'] ?? 1) as int : 1;
                
                return Expanded(
                  flex: colSpan,
                  child: Padding(
                    padding: EdgeInsets.all(spacing / 2),
                    child: SizedBox(
                      height: (60 * rowSpan).toDouble(),
                      child: CalculatorButton(
                        label: label,
                        onPressed: () => onButtonPressed(label),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      );
    } else {
      // Use standard GridView for simple buttons
      final totalButtons = buttons.expand((row) => row).length;
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: maxCols,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: totalButtons,
        itemBuilder: (context, index) {
          final flatButtons = buttons
              .expand((row) => row as List)
              .toList();
          final button = flatButtons[index];
          return CalculatorButton(
            label: button,
            onPressed: () => onButtonPressed(button),
          );
        },
      );
    }
  }

  Widget _buildConverterUI(BuildContext context, Map<String, dynamic> ui) {
    final layout = ui['layout'];
    final widgets = layout['widgets'] as List<dynamic>;
    final padding = layout['padding'] ?? 16.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.module.name), elevation: 0),
      body: Padding(
        padding: EdgeInsets.all(padding.toDouble()),
        child: ListView(
          children: widgets.map((widgetConfig) {
            final padding = widgetConfig['padding'] ?? {};

            final top = (padding['top'] ?? 0).toDouble();
            final bottom = (padding['bottom'] ?? 0).toDouble();
            final left = (padding['left'] ?? 0).toDouble();
            final right = (padding['right'] ?? 0).toDouble();

            return Padding(
              padding: EdgeInsets.only(
                top: top,
                bottom: bottom,
                left: left,
                right: right,
              ),
              child: _buildWidget(widgetConfig),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWidget(Map<String, dynamic> config) {
    final type = config['type'];

    switch (type) {
      case 'text_input':
        return TextField(
          decoration: InputDecoration(
            labelText: config['label'],
            border: const OutlineInputBorder(),
          ),
          keyboardType: config['input_type'] == 'number'
              ? TextInputType.number
              : TextInputType.text,
          controller: TextEditingController(text: formData[config['key']]),
          onChanged: (value) => formData[config['key']] = value,
        );

      case 'dropdown':
        final options = (config['options'] as List<dynamic>).cast<String>();
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: config['label'],
            border: const OutlineInputBorder(),
          ),
          value: formData[config['key']]?.isEmpty ?? true
              ? null
              : formData[config['key']],
          items: options.map((option) {
            return DropdownMenuItem(value: option, child: Text(option));
          }).toList(),
          onChanged: (value) {
            setState(() {
              formData[config['key']] = value!;
            });
          },
        );

      case 'text_display':
        return TextField(
          decoration: InputDecoration(
            labelText: config['label'],
            border: const OutlineInputBorder(),
          ),
          readOnly: true,
          controller: TextEditingController(text: formData[config['key']]),
        );

      case 'button_row':
        final buttons = config['buttons'] as List<dynamic>;
        return Row(
          children: buttons.map((button) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ElevatedButton(
                  onPressed: () => onActionPressed(button['action']),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Text(button['label']),
                ),
              ),
            );
          }).toList(),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
