import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/modules_provider.dart';
import '../providers/history_provider.dart';
import '../providers/appearance_provider.dart';
import '../providers/auth_provider.dart';
import '../models/history_entry.dart';
import '../models/module.dart';
import 'module_screen.dart';
import 'grundrechner_screen.dart';
import 'admin_screen.dart';
import 'appearance_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modulesState = ref.watch(modulesProvider);
    final history = ref.watch(historyProvider);
    final app = ref.watch(appearanceProvider);

    final activeModules = modulesState.active;

    return Scaffold(
      backgroundColor: app.backgroundColor,
      appBar: AppBar(
        title: const Text('JustForYou'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Erscheinungsbild',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Admin',
            onPressed: () => _showAdminLogin(context, ref),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Module tiles
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Module',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: app.fontSize + 2,
                  color: Colors.grey[700],
                )),
          ),

          // Grundrechner is always available + active branch modules
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _ModuleTile(
                  icon: Icons.calculate,
                  label: 'Grundrechner',
                  color: const Color(0xFF1565C0),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GrundrechnerScreen()),
                  ),
                ),
                ...activeModules.map((m) => _ModuleTile(
                      icon: _iconFor(m),
                      label: m.name,
                      color: _colorFor(m),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ModuleScreen(module: m)),
                      ),
                    )),
                if (activeModules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Center(
                      child: Text(
                        'Keine Module aktiv\n(Admin → Module aktivieren)',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 24),

          // History header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ergebnisliste',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: app.fontSize + 2,
                      color: Colors.grey[700],
                    )),
                if (history.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _confirmClearHistory(context, ref),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Löschen'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
              ],
            ),
          ),

          // History list
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Noch keine Berechnungen',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: app.fontSize),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: history.length,
                    itemBuilder: (context, i) =>
                        _HistoryTile(entry: history[i], fontSize: app.fontSize),
                  ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(Module m) {
    final id = (m.ui['module_id'] ?? '') as String;
    switch (id) {
      case 'prozentrechnung': return Icons.percent;
      case 'kreditberechnung': return Icons.account_balance;
      case 'mathematik': return Icons.functions;
      case 'schule': return Icons.school;
      case 'informationstechnik': return Icons.computer;
      default: return Icons.apps;
    }
  }

  Color _colorFor(Module m) {
    final id = (m.ui['module_id'] ?? '') as String;
    switch (id) {
      case 'prozentrechnung': return Colors.green.shade700;
      case 'kreditberechnung': return Colors.orange.shade700;
      case 'mathematik': return Colors.purple.shade700;
      case 'schule': return Colors.teal.shade700;
      case 'informationstechnik': return Colors.red.shade700;
      default: return Colors.blueGrey.shade700;
    }
  }

  Future<void> _showAdminLogin(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    if (authState.isAdmin) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      return;
    }
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin-Anmeldung'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Passwort',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Anmelden')),
        ],
      ),
    );
    if (ok == true) {
      final success = await ref.read(authProvider.notifier).login(ctrl.text);
      if (success && context.mounted) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AdminScreen()));
      } else if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falsches Passwort')),
        );
      }
    }
  }

  Future<void> _confirmClearHistory(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ergebnisliste löschen'),
        content: const Text('Alle Berechnungen löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(historyProvider.notifier).clearHistory();
    }
  }
}

class _ModuleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 90,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final double fontSize;

  const _HistoryTile({required this.entry, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    if (entry.isDateStamp) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                entry.text,
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: fontSize * 0.85,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            entry.isSideCalc ? Icons.subdirectory_arrow_right : Icons.chevron_right,
            size: 18,
            color: entry.isSideCalc ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(
                fontSize: fontSize,
                fontFamily: 'monospace',
                color: entry.isSideCalc ? Colors.blue.shade700 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
