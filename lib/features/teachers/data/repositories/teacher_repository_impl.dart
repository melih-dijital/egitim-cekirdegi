import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  final SupabaseClient _supabase;

  TeacherRepositoryImpl(this._supabase);

  @override
  Future<Either<Failure, List<Teacher>>> getTeachers(String schoolId) async {
    try {
      final response = await _supabase
          .from('teachers')
          .select()
          .eq('school_id', schoolId);

      final teachers = (response as List).map((json) {
        return Teacher(
          id: json['id'],
          name: json['name'],
          branch: json['branch'],
          schoolId: json['school_id'] ?? 'school-1',
          availableDays: json['available_days'] != null
              ? List<dynamic>.from(
                  json['available_days'],
                ).map((e) => e.toString()).toList()
              : [],
        );
      }).toList();

      return right(teachers);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addTeacher(Teacher teacher) async {
    try {
      await _supabase.from('teachers').insert({
        'id': teacher.id,
        'name': teacher.name,
        'branch': teacher.branch,
        'available_days': teacher.availableDays,
        'school_id': teacher.schoolId,
      });
      return right(null);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTeacher(String teacherId) async {
    try {
      await _supabase.from('teachers').delete().eq('id', teacherId);
      return right(null);
    } catch (e) {
      return left(ServerFailure(e.toString()));
    }
  }
}
