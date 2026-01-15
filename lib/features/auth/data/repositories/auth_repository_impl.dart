import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabaseClient;
  // Constant for temp domain
  static const String tempDomain = 'temp.okulasistan.com';

  AuthRepositoryImpl(this._supabaseClient);

  @override
  Future<Either<Failure, User>> login({
    required String identifier,
    String? password,
  }) async {
    try {
      String email;
      String finalPassword;

      // 6-Digit Code Check (Digits only, length 6)
      final isSixDigitCode = RegExp(r'^\d{6}$').hasMatch(identifier);

      if (isSixDigitCode) {
        // Shadow Account Logic
        email = '$identifier@$tempDomain';
        // Password is the code itself for initial login
        finalPassword = identifier;
      } else {
        // Standard Email Login
        email = identifier;
        if (password == null || password.isEmpty) {
          return left(const AuthFailure('Şifre gereklidir.'));
        }
        finalPassword = password;
      }

      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: finalPassword,
      );

      if (response.user != null) {
        return right(response.user!);
      } else {
        return left(
          const AuthFailure('Giriş yapılamadı: Kullanıcı bulunamadı.'),
        );
      }
    } on AuthException catch (e) {
      if (e.message.contains('Invalid execution')) {
        return left(const AuthFailure('Geçersiz kod veya şifre.'));
      }
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> linkEmail({
    required String newEmail,
    required String newPassword,
  }) async {
    try {
      final UserAttributes attrs = UserAttributes(
        email: newEmail,
        password: newPassword,
      );

      await _supabaseClient.auth.updateUser(attrs);
      return right(null);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
      return right(null);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  User? get currentUser => _supabaseClient.auth.currentUser;
}
