import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../domain/entities/entities.dart';
import 'package:uuid/uuid.dart';

// Students Management
class StudentsNotifier extends StateNotifier<List<Student>> {
  final Ref ref;
  StudentsNotifier(this.ref) : super([]);

  Future<void> pickAndImportFile() async {
    final fileService = ref.read(fileServiceProvider);

    // Pick File
    final result = await fileService.pickFile();
    if (result == null) return; // User canceled

    final bytes = result.files.single.bytes;
    if (bytes == null) return; // Should be handled for web/desktop

    // Parse
    // Assuming Excel for now. Could check extension.
    final rows = fileService.parseExcel(bytes);

    // Map to Student Objects
    // Skip header (row 0) if necessary, assuming Row 0 is header
    final List<Student> newStudents = [];
    final uuid = const Uuid();

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 3) continue; // Basic validation check

      // Expected: No, Name, Class-Section
      final student = Student(
        id: uuid.v4(),
        number: row[0].toString(),
        name: row[1].toString(),
        className: row[2]
            .toString()
            .split('-')[0]
            .trim(), // e.g. "9" from "9-A"
        branch: row.length > 3
            ? row[3].toString()
            : (row[2].toString().contains('-')
                  ? row[2].toString().split('-')[1]
                  : 'A'),
      );
      newStudents.add(student);
    }

    state = [...state, ...newStudents];
  }

  void addStudent(Student student) {
    state = [...state, student];
  }
}

final studentsProvider = StateNotifierProvider<StudentsNotifier, List<Student>>(
  (ref) {
    return StudentsNotifier(ref);
  },
);

// Halls Management (Simple State)
final hallsProvider = StateProvider<List<ExamHall>>((ref) => []);

// Distribution Logic
class DistributionNotifier
    extends StateNotifier<AsyncValue<List<ExamPlacement>>> {
  final Ref ref;

  DistributionNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> distribute(List<Student> students, List<ExamHall> halls) async {
    state = const AsyncValue.loading();

    // Simulate processing
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final distributor = ref.read(butterflyDistributorProvider);
      final resultMap = distributor.distribute(
        students: students,
        halls: halls,
      );

      // Flatten results
      final List<ExamPlacement> flatList = [];
      for (var list in resultMap.values) {
        flatList.addAll(list);
      }

      state = AsyncValue.data(flatList);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final distributionProvider =
    StateNotifierProvider<
      DistributionNotifier,
      AsyncValue<List<ExamPlacement>>
    >((ref) {
      return DistributionNotifier(ref);
    });
