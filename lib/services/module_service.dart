import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/module.dart';

class ModuleService {
  Future<Module?> importModule() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null) {
        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);

        final appDir = await getApplicationDocumentsDirectory();
        final moduleDir = Directory(
          '${appDir.path}/modules/${DateTime.now().millisecondsSinceEpoch}',
        );
        await moduleDir.create(recursive: true);

        for (final fileEntry in archive) {
          final filename = '${moduleDir.path}/${fileEntry.name}';
          if (fileEntry.isFile) {
            final data = fileEntry.content as List<int>;
            final outFile = File(filename);
            await outFile.create(recursive: true);
            await outFile.writeAsBytes(data);
          } else {
            await Directory(filename).create(recursive: true);
          }
        }

        // Read ui.json - try different paths
        File uiFile = File('${moduleDir.path}/ui.json');
        if (!await uiFile.exists()) {
          // Try inside subfolder
          final subDirs = moduleDir.listSync().whereType<Directory>();
          if (subDirs.isNotEmpty) {
            uiFile = File('${subDirs.first.path}/ui.json');
          }
        }

        if (await uiFile.exists()) {
          final uiJson = await uiFile.readAsString();
          final uiData = jsonDecode(uiJson);
          return Module(
            name: uiData['name'] ?? 'Unknown',
            description: uiData['description'] ?? '',
            path: moduleDir.path,
            ui: uiData,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }
}
