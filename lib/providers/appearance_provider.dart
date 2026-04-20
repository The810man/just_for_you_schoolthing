import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppearanceState {
  final double fontSize;
  final Color backgroundColor;
  final String fontFamily;

  const AppearanceState({
    this.fontSize = 16.0,
    this.backgroundColor = Colors.white,
    this.fontFamily = 'Default',
  });

  AppearanceState copyWith({
    double? fontSize,
    Color? backgroundColor,
    String? fontFamily,
  }) =>
      AppearanceState(
        fontSize: fontSize ?? this.fontSize,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        fontFamily: fontFamily ?? this.fontFamily,
      );
}

class AppearanceNotifier extends StateNotifier<AppearanceState> {
  AppearanceNotifier() : super(const AppearanceState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = AppearanceState(
      fontSize: prefs.getDouble('fontSize') ?? 16.0,
      backgroundColor: Color(prefs.getInt('bgColor') ?? 0xFFFFFFFF),
      fontFamily: prefs.getString('fontFamily') ?? 'Default',
    );
  }

  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', size);
  }

  Future<void> setBackgroundColor(Color color) async {
    state = state.copyWith(backgroundColor: color);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bgColor', color.toARGB32());
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fontFamily', family);
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceNotifier, AppearanceState>(
  (ref) => AppearanceNotifier(),
);
