import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login({
    required String identifier,
    String? password,
  });

  Future<Either<Failure, void>> linkEmail({
    required String newEmail,
    required String newPassword,
  });

  Future<Either<Failure, void>> signOut();

  User? get currentUser;
}
