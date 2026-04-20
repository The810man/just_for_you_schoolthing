import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class AuthState {
  final bool setupDone;
  final bool isAdmin;
  final bool loading;

  const AuthState({
    this.setupDone = false,
    this.isAdmin = false,
    this.loading = true,
  });

  AuthState copyWith({bool? setupDone, bool? isAdmin, bool? loading}) =>
      AuthState(
        setupDone: setupDone ?? this.setupDone,
        isAdmin: isAdmin ?? this.isAdmin,
        loading: loading ?? this.loading,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    final done = await AuthService.isSetupDone();
    state = state.copyWith(setupDone: done, loading: false);
  }

  Future<void> setupPassword(String password) async {
    await AuthService.setupPassword(password);
    state = state.copyWith(setupDone: true, isAdmin: true);
  }

  Future<bool> login(String password) async {
    final ok = await AuthService.checkPassword(password);
    if (ok) state = state.copyWith(isAdmin: true);
    return ok;
  }

  void logout() => state = state.copyWith(isAdmin: false);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
