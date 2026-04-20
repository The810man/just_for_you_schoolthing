import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/appearance_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  static const _fonts = ['Default', 'Monospace', 'Serif', 'SansSerif'];
  static const _colors = [
    Colors.white,
    Color(0xFFF3F4F6),
    Color(0xFFE3F2FD),
    Color(0xFFE8F5E9),
    Color(0xFFFFF3E0),
    Color(0xFFFCE4EC),
    Color(0xFF212121),
  ];
  static const _colorNames = [
    'Weiß', 'Hellgrau', 'Hellblau', 'Hellgrün', 'Hellorange', 'Hellrosa', 'Dunkel'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appearanceProvider);
    final notifier = ref.read(appearanceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Erscheinungsbild')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Font size
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Schriftgröße: ${app.fontSize.toInt()} pt',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: app.fontSize,
                    min: 12,
                    max: 28,
                    divisions: 8,
                    label: '${app.fontSize.toInt()} pt',
                    onChanged: notifier.setFontSize,
                  ),
                  Text('Beispieltext', style: TextStyle(fontSize: app.fontSize)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Font family
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Schriftart', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _fonts.map((f) {
                      final selected = app.fontFamily == f;
                      return ChoiceChip(
                        label: Text(f),
                        selected: selected,
                        onSelected: (_) => notifier.setFontFamily(f),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Background color
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hintergrundfarbe',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_colors.length, (i) {
                      final c = _colors[i];
                      final selected = app.backgroundColor.toARGB32() == c.toARGB32();
                      return GestureDetector(
                        onTap: () => notifier.setBackgroundColor(c),
                        child: Tooltip(
                          message: _colorNames[i],
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: c,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: selected ? Colors.blue : Colors.grey.shade400,
                                width: selected ? 3 : 1,
                              ),
                            ),
                            child: selected
                                ? Icon(Icons.check,
                                    color: c.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white)
                                : null,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Preview
          Card(
            color: app.backgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vorschau', style: TextStyle(fontSize: app.fontSize, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'JustForYou – Modularer Rechner\n'
                    'Ergebnis: 1.234,56 €\n'
                    '12 + 4 × 2,6 = 22,4',
                    style: TextStyle(
                      fontSize: app.fontSize,
                      fontFamily: app.fontFamily == 'Default' ? null : app.fontFamily.toLowerCase(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
