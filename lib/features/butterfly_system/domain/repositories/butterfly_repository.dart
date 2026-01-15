import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/entities.dart';

abstract class ButterflyRepository {
  Future<Either<Failure, void>> addStudent(Student student);
  Future<Either<Failure, void>> addHall(ExamHall hall);
  Future<Either<Failure, List<ExamPlacement>>> distributeStudents({
    required List<Student> students,
    required List<ExamHall> halls,
  });
}
