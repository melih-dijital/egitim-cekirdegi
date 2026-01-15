import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/init/supabase_init.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

// Dependency Injection for Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthRepositoryImpl(supabase);
});

// Auth State Provider
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((
  ref,
) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = _repository.currentUser;
    state = AsyncValue.data(user);
  }

  Future<void> login(String identifier, String? password) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(
      identifier: identifier,
      password: password,
    );

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<void> linkEmail({
    required String newEmail,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.linkEmail(
      newEmail: newEmail,
      newPassword: newPassword,
    );

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (_) {
        // Refresh state
        _checkCurrentUser();
      },
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }
}
