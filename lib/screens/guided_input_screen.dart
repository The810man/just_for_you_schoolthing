import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../providers/appearance_provider.dart';
import '../services/calc_service.dart';
import '../widgets/number_keyboard.dart';
import 'grundrechner_screen.dart';

class ModuleFunction {
  final String id;
  final String label;
  final List<Map<String, String>> params; // [{key, label, unit, hint}]

  const ModuleFunction({
    required this.id,
    required this.label,
    required this.params,
  });
}

class GuidedInputScreen extends ConsumerStatefulWidget {
  final ModuleFunction function;
  final String moduleId;

  const GuidedInputScreen({
    super.key,
    required this.function,
    required this.moduleId,
  });

  @override
  ConsumerState<GuidedInputScreen> createState() => _GuidedInputScreenState();
}

class _GuidedInputScreenState extends ConsumerState<GuidedInputScreen> {
  int _step = 0;
  String _currentInput = '';
  final Map<String, double> _values = {};
  CalcResult? _result;

  List<Map<String, String>> get _params => widget.function.params;
  bool get _isDone => _result != null;

  void _onKey(String key) {
    if (_isDone) return;
    setState(() {
      if (key == 'C') {
        _currentInput = '';
      } else if (key == '⌫') {
        if (_currentInput.isNotEmpty) {
          _currentInput = _currentInput.substring(0, _currentInput.length - 1);
        }
      } else if (key == ',' || key == '.') {
        if (!_currentInput.contains('.')) _currentInput += '.';
      } else if (key == '±') {
        if (_currentInput.startsWith('-')) {
          _currentInput = _currentInput.substring(1);
        } else if (_currentInput.isNotEmpty) {
          _currentInput = '-$_currentInput';
        }
      } else {
        _currentInput += key;
      }
    });
  }

  void _next() {
    final raw = _currentInput.replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null && _currentInput.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültige Zahl')),
      );
      return;
    }
    if (v == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Wert eingeben')),
      );
      return;
    }

    final key = _params[_step]['key']!;
    _values[key] = v;

    if (_step < _params.length - 1) {
      setState(() {
        _step++;
        _currentInput = '';
      });
    } else {
      _calculate();
    }
  }

  Future<void> _openSideCalc() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
          builder: (_) => const GrundrechnerScreen(isModal: true)),
    );
    if (result != null) {
      setState(() => _currentInput = result);
    }
  }

  Future<void> _calculate() async {
    final res = _runCalculation();
    setState(() => _result = res);
    if (!res.error) {
      await ref
          .read(historyProvider.notifier)
          .addEntry(res.historyText);
    }
  }

  CalcResult _runCalculation() {
    final v = _values;
    final fid = widget.function.id;
    final mid = widget.moduleId;

    try {
      switch (mid) {
        case 'prozentrechnung':
          switch (fid) {
            case 'prozent_dazu':
              return CalcService.prozentDazu(v['grundwert']!, v['prozentsatz']!);
            case 'prozent_weg':
              return CalcService.prozentWeg(v['grundwert']!, v['prozentsatz']!);
            case 'prozent_davon':
              return CalcService.prozentDavon(v['grundwert']!, v['prozentsatz']!);
            case 'prozent_satz':
              return CalcService.prozentSatz(v['grundwert']!, v['prozentwert']!);
            case 'brutto_aus_netto':
              return CalcService.bruttoAusNetto(v['netto']!, v['mwst']!);
            case 'netto_aus_brutto':
              return CalcService.nettoAusBrutto(v['brutto']!, v['mwst']!);
          }
          break;
        case 'kreditberechnung':
          switch (fid) {
            case 'kredit_einmalig':
              return CalcService.kreditEinmalig(
                  v['kreditbetrag']!, v['zinssatz']!, v['laufzeit']!);
            case 'ratenkredit_laufzeit':
              return CalcService.ratenkreditLaufzeit(
                  v['kreditbetrag']!, v['zinssatz']!, v['laufzeit']!);
            case 'ratenkredit_rate':
              return CalcService.ratenkreditRate(
                  v['kreditbetrag']!, v['zinssatz']!, v['rate']!);
          }
          break;
        case 'mathematik':
          switch (fid) {
            case 'fakultaet':
              return CalcService.fakultaet(v['n']!);
            case 'quadratwurzel':
              return CalcService.quadratwurzel(v['n']!);
            case 'potenz':
              return CalcService.potenz(v['basis']!, v['exponent']!);
            case 'primzahlen':
              return CalcService.primzahlen(v['untere']!, v['obere']!);
            case 'dezimal_bruch':
              return CalcService.dezimalZuBruch(v['dezimal']!);
          }
          break;
        case 'schule':
          if (fid == 'zeugnisnoten') {
            final noten = <double>[];
            int i = 1;
            while (v.containsKey('note_$i')) {
              final n = v['note_$i']!;
              if (n >= 1 && n <= 6) noten.add(n);
              i++;
            }
            return CalcService.zeugnisnote(noten);
          }
          break;
        case 'informationstechnik':
          switch (fid) {
            case 'grafikspeicher':
              return CalcService.grafikspeicher(
                  v['breite']!, v['hoehe']!, v['farbtiefe']!, 0, 0);
            case 'videodatei':
              return CalcService.grafikspeicher(
                  v['breite']!, v['hoehe']!, v['farbtiefe']!, v['fps']!, v['sekunden']!);
            case 'zahlensystem':
              return CalcService.zahlensystem(v['zahl']!, v['basis']!);
            case 'datenmenge':
              final einheiten = ['bit', 'Byte', 'KiB', 'MiB', 'GiB', 'KB', 'MB', 'GB'];
              final idx = v['einheit_idx']?.toInt() ?? 0;
              final einheit = einheiten.elementAt(idx.clamp(0, einheiten.length - 1));
              return CalcService.datenmenge(v['wert']!, einheit);
          }
          break;
      }
    } catch (e) {
      return CalcResult(values: {'Fehler': e.toString()}, historyText: '', error: true);
    }
    return CalcResult(values: {'Fehler': 'Unbekannte Funktion'}, historyText: '', error: true);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appearanceProvider);
    final textStyle = TextStyle(
      fontSize: app.fontSize,
      fontFamily: app.fontFamily == 'Default' ? null : app.fontFamily.toLowerCase(),
    );

    return Scaffold(
      backgroundColor: app.backgroundColor,
      appBar: AppBar(
        title: Text(widget.function.label),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: _isDone ? _buildResult(context, textStyle) : _buildInput(context, textStyle),
    );
  }

  Widget _buildInput(BuildContext context, TextStyle textStyle) {
    final param = _params[_step];
    final label = param['label'] ?? '';
    final unit = param['unit'] ?? '';
    final hint = param['hint'] ?? '';
    final isLast = _step == _params.length - 1;

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_step + 1) / _params.length,
          backgroundColor: Colors.grey.shade200,
          color: const Color(0xFF1565C0),
        ),

        // Step indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Schritt ${_step + 1} von ${_params.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              TextButton.icon(
                onPressed: _openSideCalc,
                icon: const Icon(Icons.calculate_outlined, size: 18),
                label: const Text('Nebenrechnung'),
              ),
            ],
          ),
        ),

        // Parameter label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            color: const Color(0xFF1565C0).withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: textStyle.copyWith(
                          fontWeight: FontWeight.bold, fontSize: (textStyle.fontSize ?? 16) + 4)),
                  if (hint.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('z.B. $hint',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Input display
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1565C0), width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _currentInput.isEmpty ? '0' : _currentInput,
                  style: textStyle.copyWith(
                    fontSize: (textStyle.fontSize ?? 16) * 1.8,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(unit,
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: (textStyle.fontSize ?? 16) * 1.2)),
              ],
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Keyboard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: NumberKeyboard(onKey: _onKey),
          ),
        ),

        // Next button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _next,
              icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
              label: Text(isLast ? 'Berechnen' : 'Weiter',
                  style: const TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResult(BuildContext context, TextStyle textStyle) {
    final res = _result!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Result header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: res.error
                        ? Colors.red.shade50
                        : const Color(0xFF1565C0).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: res.error ? Colors.red : const Color(0xFF1565C0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            res.error ? Icons.error_outline : Icons.check_circle_outline,
                            color: res.error ? Colors.red : const Color(0xFF1565C0),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            res.error ? 'Fehler' : 'Ergebnis',
                            style: textStyle.copyWith(
                                fontWeight: FontWeight.bold,
                                color: res.error ? Colors.red : const Color(0xFF1565C0)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...res.values.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text('${e.key}:',
                                      style: textStyle.copyWith(
                                          color: Colors.grey[700])),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    e.value,
                                    style: textStyle.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace'),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                if (!res.error) ...[
                  const SizedBox(height: 16),
                  // History entry preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            res.historyText,
                            style: TextStyle(color: Colors.grey[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _step = 0;
                      _currentInput = '';
                      _values.clear();
                      _result = null;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Neue Berechnung'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Zurück'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
