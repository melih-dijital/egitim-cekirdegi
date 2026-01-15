import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/duty.dart';
import '../../domain/repositories/duty_repository.dart';

class DutyRepositoryImpl implements DutyRepository {
  final SupabaseClient _supabase;

  DutyRepositoryImpl(this._supabase);

  @override
  Future<Either<Failure, List<Duty>>> getDuties({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final response = await _supabase
          .from('duties')
          .select()
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String());

      final duties = (response as List).map((json) {
        return Duty(
          id: json['id'],
          schoolId: json['school_id'],
          date: DateTime.parse(json['date']),
          area: json['area'],
          teacherId: json['teacher_id'],
          teacherName:
              json['teacher_name'] ?? 'Unknown', // Ideally fetch from relation
        );
      }).toList();

      return right(duties);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createDutyPlan({
    required DateTime start,
    required DateTime end,
    required List<String> areas,
  }) async {
    // This method signature in interface was for "triggering creation".
    // Since creation details are handled by Distributor, we might want a method to "saveDuties" instead.
    // For now, let's assume this just returns success or we update the interface to save duties.
    return right(null);
  }

  Future<Either<Failure, void>> saveDuties(List<Duty> duties) async {
    try {
      final data = duties
          .map(
            (duty) => {
              'id': duty.id,
              'school_id': duty.schoolId,
              'date': duty.date.toIso8601String(),
              'area': duty.area,
              'teacher_id': duty.teacherId,
              'teacher_name':
                  duty.teacherName, // Denormalized or handled by trigger
            },
          )
          .toList();

      await _supabase.from('duties').upsert(data);
      return right(null);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
