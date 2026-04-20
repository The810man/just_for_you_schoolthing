import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/module.dart';

class ModulesState {
  final List<Module> installed; // all imported modules
  final List<String> activeIds; // names of active modules (max 3)

  const ModulesState({this.installed = const [], this.activeIds = const []});

  List<Module> get active =>
      installed.where((m) => activeIds.contains(m.name)).toList();

  ModulesState copyWith({List<Module>? installed, List<String>? activeIds}) =>
      ModulesState(
        installed: installed ?? this.installed,
        activeIds: activeIds ?? this.activeIds,
      );
}

class ModulesNotifier extends StateNotifier<ModulesState> {
  ModulesNotifier() : super(const ModulesState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final installedJson = prefs.getStringList('modules_installed') ?? [];
    final activeIds = prefs.getStringList('modules_active') ?? [];
    final installed =
        installedJson.map((j) => Module.fromJson(jsonDecode(j))).toList();
    state = ModulesState(installed: installed, activeIds: activeIds);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'modules_installed',
      state.installed.map((m) => jsonEncode(m.toJson())).toList(),
    );
    await prefs.setStringList('modules_active', state.activeIds);
  }

  Future<void> addModule(Module module) async {
    // Replace if name already exists
    final updated = state.installed.where((m) => m.name != module.name).toList()
      ..add(module);
    state = state.copyWith(installed: updated);
    await _save();
  }

  Future<void> removeModule(String name) async {
    final updated = state.installed.where((m) => m.name != name).toList();
    final activeIds = state.activeIds.where((id) => id != name).toList();
    state = ModulesState(installed: updated, activeIds: activeIds);
    await _save();
  }

  Future<bool> toggleActive(String name) async {
    final activeIds = [...state.activeIds];
    if (activeIds.contains(name)) {
      activeIds.remove(name);
    } else {
      if (activeIds.length >= 3) return false; // max 3 reached
      activeIds.add(name);
    }
    state = state.copyWith(activeIds: activeIds);
    await _save();
    return true;
  }

  // For backward compat
  void addModuleDirect(Module module) => addModule(module);
}

final modulesProvider =
    StateNotifierProvider<ModulesNotifier, ModulesState>((ref) {
  return ModulesNotifier();
});
