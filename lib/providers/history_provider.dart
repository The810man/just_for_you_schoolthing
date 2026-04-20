import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  HistoryNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('history') ?? [];
    state = list.map((s) => HistoryEntry.fromJson(jsonDecode(s))).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'history',
      state.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> addEntry(String text, {bool isSideCalc = false}) async {
    final now = DateTime.now();
    // Check if today's date stamp already exists
    final today = DateTime(now.year, now.month, now.day);
    final hasStamp = state.any((e) {
      final d = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return e.isDateStamp && d == today;
    });

    final newEntries = <HistoryEntry>[];
    if (!hasStamp) {
      newEntries.add(HistoryEntry(
        id: 'ds_${now.millisecondsSinceEpoch}',
        timestamp: now,
        text: '── ${_fmtDate(now)} ──',
        isDateStamp: true,
      ));
    }
    newEntries.add(HistoryEntry(
      id: '${now.millisecondsSinceEpoch}',
      timestamp: now,
      text: text,
      isSideCalc: isSideCalc,
    ));
    state = [...state, ...newEntries];
    await _save();
  }

  Future<void> clearHistory() async {
    state = [];
    await _save();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>(
  (ref) => HistoryNotifier(),
);
