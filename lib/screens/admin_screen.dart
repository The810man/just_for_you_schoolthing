import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/modules_provider.dart';
import '../services/auth_service.dart';
import '../models/module.dart';
import 'appearance_screen.dart';

// All bundled module assets
const _bundledModules = [
  {'asset': 'assets/modules/prozentrechnung.zip', 'name': 'Prozentrechnung'},
  {'asset': 'assets/modules/kreditberechnung.zip', 'name': 'Kreditberechnung'},
  {'asset': 'assets/modules/mathematik.zip', 'name': 'Mathematik'},
  {'asset': 'assets/modules/schule.zip', 'name': 'Schule'},
  {
    'asset': 'assets/modules/informationstechnik.zip',
    'name': 'Informationstechnik'
  },
];

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  bool _loading = false;

  Future<Module?> _loadModuleFromAsset(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final archive =
          ZipDecoder().decodeBytes(bytes.buffer.asUint8List());

      final appDir = await getApplicationDocumentsDirectory();
      final name = assetPath.split('/').last.replaceAll('.zip', '');
      final moduleDir =
          Directory('${appDir.path}/modules/$name');
      await moduleDir.create(recursive: true);

      for (final entry in archive) {
        final path = '${moduleDir.path}/${entry.name}';
        if (entry.isFile) {
          final f = File(path);
          await f.create(recursive: true);
          await f.writeAsBytes(entry.content as List<int>);
        } else {
          await Directory(path).create(recursive: true);
        }
      }

      File uiFile = File('${moduleDir.path}/ui.json');
      if (!await uiFile.exists()) {
        final subs = moduleDir.listSync().whereType<Directory>();
        if (subs.isNotEmpty) {
          uiFile = File('${subs.first.path}/ui.json');
        }
      }
      if (!await uiFile.exists()) return null;

      final uiData = jsonDecode(await uiFile.readAsString());
      return Module(
        name: uiData['name'] ?? name,
        description: uiData['description'] ?? '',
        path: moduleDir.path,
        ui: uiData,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _installModule(String assetPath, String displayName) async {
    setState(() => _loading = true);
    try {
      final module = await _loadModuleFromAsset(assetPath);
      if (module != null) {
        await ref.read(modulesProvider.notifier).addModule(module);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Modul "${module.name}" installiert'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _installAllModules() async {
    setState(() => _loading = true);
    int count = 0;
    for (final m in _bundledModules) {
      final module = await _loadModuleFromAsset(m['asset']!);
      if (module != null) {
        await ref.read(modulesProvider.notifier).addModule(module);
        count++;
      }
    }
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count Module installiert'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modulesState = ref.watch(modulesProvider);
    final notifier = ref.read(modulesProvider.notifier);

    final installedNames =
        modulesState.installed.map((m) => m.name).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin-Bereich'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset),
            tooltip: 'Passwort zurücksetzen',
            onPressed: () => _confirmResetPassword(context),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            tooltip: 'Erscheinungsbild',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Module werden geladen...'),
                ],
              ),
            )
          : Column(
              children: [
                // Info banner
                Container(
                  color: const Color(0xFF1565C0).withAlpha(20),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aktive Module: ${modulesState.activeIds.length}/3  '
                          '(Toggle = aktiv für Nutzer)',
                          style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

                // Available (bundled) modules to install
                if (modulesState.installed.isEmpty ||
                    _bundledModules.any(
                        (m) => !installedNames.contains(m['name']))) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Verfügbare Module',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _installAllModules,
                          icon: const Icon(Icons.download_for_offline),
                          label: const Text('Alle installieren'),
                        ),
                      ],
                    ),
                  ),
                  ...(_bundledModules
                      .where((m) => !installedNames.contains(m['name']))
                      .map((m) => ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE3F2FD),
                              child: Icon(Icons.extension,
                                  color: Color(0xFF1565C0)),
                            ),
                            title: Text(m['name']!),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  _installModule(m['asset']!, m['name']!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Installieren'),
                            ),
                          ))),
                  const Divider(height: 24),
                ],

                // Installed modules
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Installierte Module',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: modulesState.installed.isEmpty
                      ? const Center(
                          child: Text(
                            'Noch keine Module installiert.\n'
                            'Oben ein Modul installieren.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: modulesState.installed.length,
                          itemBuilder: (context, i) {
                            final m = modulesState.installed[i];
                            final isActive =
                                modulesState.activeIds.contains(m.name);
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isActive
                                      ? const Color(0xFF1565C0)
                                      : Colors.grey.shade300,
                                  child: Icon(Icons.apps,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.grey),
                                ),
                                title: Text(m.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(m.description),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: isActive,
                                      onChanged: (_) async {
                                        final ok = await notifier
                                            .toggleActive(m.name);
                                        if (!ok && context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Maximal 3 Module aktiv'),
                                          ));
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          color: Colors.red),
                                      onPressed: () => _confirmDelete(
                                          context, m.name, notifier),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _confirmResetPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Passwort zurücksetzen'),
        content: const Text(
            'Admin-Passwort wirklich zurücksetzen? '
            'Beim nächsten Start kann ein neues Passwort vergeben werden.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () async {
              await AuthService.resetSetup();
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ref.read(authProvider.notifier).logout();
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, String name, ModulesNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modul entfernen'),
        content: Text('Modul "$name" wirklich entfernen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          TextButton(
            onPressed: () {
              notifier.removeModule(name);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
