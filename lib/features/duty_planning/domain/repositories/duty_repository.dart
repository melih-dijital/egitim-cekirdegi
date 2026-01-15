import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/duty.dart';

abstract class DutyRepository {
  Future<Either<Failure, List<Duty>>> getDuties({
    required DateTime start,
    required DateTime end,
  });
  Future<Either<Failure, void>> createDutyPlan({
    required DateTime start,
    required DateTime end,
    required List<String> areas,
  });
}
