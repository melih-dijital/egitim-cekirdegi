import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../error/failures.dart';

class MockAuthRepository implements AuthRepository {
  @override
  User? get currentUser => const User(
    id: 'mock-user-id',
    appMetadata: {},
    userMetadata: {'role': 'admin'},
    aud: 'authenticated',
    createdAt: '2024-01-01',
  );

  @override
  Future<Either<Failure, User>> login({
    required String identifier,
    String? password,
  }) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate delay
    if (identifier == 'error') {
      return left(const AuthFailure('Mock Error: Invalid credentials'));
    }
    return right(
      const User(
        id: 'mock-user-id',
        appMetadata: {},
        userMetadata: {'role': 'admin', 'school_id': 'school-1'},
        aud: 'authenticated',
        createdAt: '2024-01-01',
      ),
    );
  }

  @override
  Future<Either<Failure, void>> linkEmail({
    required String newEmail,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return right(null);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return right(null);
  }
}
