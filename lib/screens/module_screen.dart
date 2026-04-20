import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/module.dart';
import '../providers/appearance_provider.dart';
import 'guided_input_screen.dart';

// All module function definitions
final Map<String, List<ModuleFunction>> _moduleFunctions = {
  'prozentrechnung': [
    ModuleFunction(
      id: 'prozent_dazu',
      label: 'Prozent dazu (%+)',
      params: [
        {'key': 'grundwert', 'label': 'Grundwert', 'unit': '', 'hint': '100'},
        {'key': 'prozentsatz', 'label': 'Prozentsatz', 'unit': '%', 'hint': '19'},
      ],
    ),
    ModuleFunction(
      id: 'prozent_weg',
      label: 'Prozent weg (%-)',
      params: [
        {'key': 'grundwert', 'label': 'Grundwert', 'unit': '', 'hint': '100'},
        {'key': 'prozentsatz', 'label': 'Prozentsatz', 'unit': '%', 'hint': '10'},
      ],
    ),
    ModuleFunction(
      id: 'prozent_davon',
      label: 'Prozentwert (% davon)',
      params: [
        {'key': 'grundwert', 'label': 'Grundwert (G)', 'unit': '', 'hint': '200'},
        {'key': 'prozentsatz', 'label': 'Prozentsatz (p)', 'unit': '%', 'hint': '15'},
      ],
    ),
    ModuleFunction(
      id: 'prozent_satz',
      label: 'Prozentsatz berechnen',
      params: [
        {'key': 'grundwert', 'label': 'Grundwert (G)', 'unit': '', 'hint': '500'},
        {'key': 'prozentwert', 'label': 'Prozentwert (W)', 'unit': '', 'hint': '75'},
      ],
    ),
    ModuleFunction(
      id: 'brutto_aus_netto',
      label: 'Bruttopreis aus Nettopreis',
      params: [
        {'key': 'netto', 'label': 'Nettopreis', 'unit': '€', 'hint': '100'},
        {'key': 'mwst', 'label': 'Mehrwertsteuersatz', 'unit': '%', 'hint': '19'},
      ],
    ),
    ModuleFunction(
      id: 'netto_aus_brutto',
      label: 'Nettopreis aus Bruttopreis',
      params: [
        {'key': 'brutto', 'label': 'Bruttopreis', 'unit': '€', 'hint': '119'},
        {'key': 'mwst', 'label': 'Mehrwertsteuersatz', 'unit': '%', 'hint': '19'},
      ],
    ),
  ],
  'kreditberechnung': [
    ModuleFunction(
      id: 'kredit_einmalig',
      label: 'Kredit – einmalige Rückzahlung',
      params: [
        {'key': 'kreditbetrag', 'label': 'Kreditbetrag', 'unit': '€', 'hint': '10000'},
        {'key': 'zinssatz', 'label': 'Zinssatz (p.a.)', 'unit': '%', 'hint': '5'},
        {'key': 'laufzeit', 'label': 'Laufzeit', 'unit': 'Monate', 'hint': '12'},
      ],
    ),
    ModuleFunction(
      id: 'ratenkredit_laufzeit',
      label: 'Ratenkredit – Laufzeit vorgeben',
      params: [
        {'key': 'kreditbetrag', 'label': 'Kreditbetrag', 'unit': '€', 'hint': '12000'},
        {'key': 'zinssatz', 'label': 'Zinssatz (p.a.)', 'unit': '%', 'hint': '10'},
        {'key': 'laufzeit', 'label': 'Laufzeit', 'unit': 'Monate', 'hint': '12'},
      ],
    ),
    ModuleFunction(
      id: 'ratenkredit_rate',
      label: 'Ratenkredit – Ratenhöhe vorgeben',
      params: [
        {'key': 'kreditbetrag', 'label': 'Kreditbetrag', 'unit': '€', 'hint': '12000'},
        {'key': 'zinssatz', 'label': 'Zinssatz (p.a.)', 'unit': '%', 'hint': '10'},
        {'key': 'rate', 'label': 'Gewünschte Rate', 'unit': '€/Monat', 'hint': '1050'},
      ],
    ),
  ],
  'mathematik': [
    ModuleFunction(
      id: 'fakultaet',
      label: 'Fakultät (n!)',
      params: [
        {'key': 'n', 'label': 'Ganzzahl n (0–20)', 'unit': '', 'hint': '5'},
      ],
    ),
    ModuleFunction(
      id: 'quadratwurzel',
      label: 'Quadratwurzel (√n)',
      params: [
        {'key': 'n', 'label': 'Zahl n', 'unit': '', 'hint': '25'},
      ],
    ),
    ModuleFunction(
      id: 'potenz',
      label: 'Potenzfunktion (aⁿ)',
      params: [
        {'key': 'basis', 'label': 'Basis (a)', 'unit': '', 'hint': '2'},
        {'key': 'exponent', 'label': 'Exponent (n)', 'unit': '', 'hint': '10'},
      ],
    ),
    ModuleFunction(
      id: 'primzahlen',
      label: 'Primzahlen (Bereich)',
      params: [
        {'key': 'untere', 'label': 'Untere Grenze', 'unit': '', 'hint': '1'},
        {'key': 'obere', 'label': 'Obere Grenze', 'unit': '', 'hint': '100'},
      ],
    ),
    ModuleFunction(
      id: 'dezimal_bruch',
      label: 'Dezimalzahl → Bruch',
      params: [
        {'key': 'dezimal', 'label': 'Dezimalzahl', 'unit': '', 'hint': '0.75'},
      ],
    ),
  ],
  'schule': [
    ModuleFunction(
      id: 'zeugnisnoten',
      label: 'Zeugnisnote berechnen',
      params: [
        {'key': 'note_1', 'label': 'Note Fach 1 (1–6)', 'unit': '', 'hint': '2'},
        {'key': 'note_2', 'label': 'Note Fach 2 (1–6, 0=kein Fach)', 'unit': '', 'hint': '3'},
        {'key': 'note_3', 'label': 'Note Fach 3 (1–6, 0=kein Fach)', 'unit': '', 'hint': '1'},
        {'key': 'note_4', 'label': 'Note Fach 4 (1–6, 0=kein Fach)', 'unit': '', 'hint': '0'},
        {'key': 'note_5', 'label': 'Note Fach 5 (1–6, 0=kein Fach)', 'unit': '', 'hint': '0'},
        {'key': 'note_6', 'label': 'Note Fach 6 (1–6, 0=kein Fach)', 'unit': '', 'hint': '0'},
        {'key': 'note_7', 'label': 'Note Fach 7 (1–6, 0=kein Fach)', 'unit': '', 'hint': '0'},
        {'key': 'note_8', 'label': 'Note Fach 8 (1–6, 0=kein Fach)', 'unit': '', 'hint': '0'},
      ],
    ),
  ],
  'informationstechnik': [
    ModuleFunction(
      id: 'grafikspeicher',
      label: 'Grafikspeichergröße',
      params: [
        {'key': 'breite', 'label': 'Breite', 'unit': 'px', 'hint': '1920'},
        {'key': 'hoehe', 'label': 'Höhe', 'unit': 'px', 'hint': '1080'},
        {'key': 'farbtiefe', 'label': 'Farbtiefe', 'unit': 'bit', 'hint': '24'},
      ],
    ),
    ModuleFunction(
      id: 'videodatei',
      label: 'Videodateigröße',
      params: [
        {'key': 'breite', 'label': 'Breite', 'unit': 'px', 'hint': '1920'},
        {'key': 'hoehe', 'label': 'Höhe', 'unit': 'px', 'hint': '1080'},
        {'key': 'farbtiefe', 'label': 'Farbtiefe', 'unit': 'bit', 'hint': '24'},
        {'key': 'fps', 'label': 'Bilder pro Sekunde', 'unit': 'fps', 'hint': '30'},
        {'key': 'sekunden', 'label': 'Videolänge', 'unit': 's', 'hint': '60'},
      ],
    ),
    ModuleFunction(
      id: 'zahlensystem',
      label: 'Zahlensystem umrechnen',
      params: [
        {'key': 'zahl', 'label': 'Zahl (als Dezimal eingeben)', 'unit': '', 'hint': '255'},
        {'key': 'basis', 'label': 'Quellbasis (10=Dezimal, 2=Binär, 8=Oktal)', 'unit': '', 'hint': '10'},
      ],
    ),
    ModuleFunction(
      id: 'datenmenge',
      label: 'Datenmenge umrechnen',
      params: [
        {'key': 'wert', 'label': 'Wert', 'unit': '', 'hint': '1'},
        {
          'key': 'einheit_idx',
          'label': 'Einheit (0=bit, 1=Byte, 2=KiB, 3=MiB, 4=GiB, 5=KB, 6=MB, 7=GB)',
          'unit': '',
          'hint': '3'
        },
      ],
    ),
  ],
};

class ModuleScreen extends ConsumerWidget {
  final Module module;

  const ModuleScreen({super.key, required this.module});

  String get _moduleId {
    final id = module.ui['module_id'] as String? ?? '';
    if (id.isNotEmpty) return id;
    // Fallback: derive from name
    return module.name.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appearanceProvider);
    final functions = _moduleFunctions[_moduleId] ?? [];

    if (functions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(module.name)),
        body: const Center(
          child: Text('Keine Funktionen für dieses Modul definiert.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: app.backgroundColor,
      appBar: AppBar(
        title: Text(module.name),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: functions.length,
        itemBuilder: (context, i) {
          final fn = functions[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor:
                    const Color(0xFF1565C0).withOpacity(0.12),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                      color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(fn.label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: app.fontSize)),
              subtitle: Text(
                '${fn.params.length} Eingabe${fn.params.length != 1 ? 'n' : ''}',
                style:
                    TextStyle(fontSize: app.fontSize * 0.85),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GuidedInputScreen(
                    function: fn,
                    moduleId: _moduleId,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
