import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/teacher.dart';

abstract class TeacherRepository {
  Future<Either<Failure, List<Teacher>>> getTeachers(String schoolId);
  Future<Either<Failure, void>> addTeacher(Teacher teacher);
  Future<Either<Failure, void>> deleteTeacher(String teacherId);
}
