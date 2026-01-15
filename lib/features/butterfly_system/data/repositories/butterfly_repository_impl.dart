import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/butterfly_repository.dart';

class ButterflyRepositoryImpl implements ButterflyRepository {
  // Mock In-Memory Storage
  final List<Student> _students = [];
  final List<ExamHall> _halls = [];

  @override
  Future<Either<Failure, void>> addStudent(Student student) async {
    _students.add(student);
    return right(null);
  }

  @override
  Future<Either<Failure, void>> addHall(ExamHall hall) async {
    _halls.add(hall);
    return right(null);
  }

  @override
  Future<Either<Failure, List<ExamPlacement>>> distributeStudents({
    required List<Student> students,
    required List<ExamHall> halls,
  }) async {
    // Mock Distribution Logic
    // In a real app, this would be a complex algorithm
    final placements = <ExamPlacement>[];

    // Simple mock logic: just fill halls sequentially
    int currentStudentIdx = 0;

    for (var hall in halls) {
      for (int i = 0; i < hall.capacity; i++) {
        if (currentStudentIdx >= students.length) break;

        placements.add(
          ExamPlacement(
            hallId: hall.id,
            studentId: students[currentStudentIdx].id,
            seatNumber: i + 1,
          ),
        );
        currentStudentIdx++;
      }
    }

    await Future.delayed(const Duration(seconds: 1)); // Simulate processing
    return right(placements);
  }
}
