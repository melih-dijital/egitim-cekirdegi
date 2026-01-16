import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/providers/global_providers.dart';
import '../../domain/entities/entities.dart';
import 'package:uuid/uuid.dart';

/// Result of file import operation
class ImportResult {
  final int successCount;
  final int errorCount;
  final String? errorMessage;

  const ImportResult({
    required this.successCount,
    this.errorCount = 0,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
  bool get hasData => successCount > 0;
}

// Students Management
class StudentsNotifier extends StateNotifier<List<Student>> {
  final Ref ref;
  StudentsNotifier(this.ref) : super([]);

  Future<ImportResult> pickAndImportFile() async {
    try {
      final fileService = ref.read(fileServiceProvider);

      // Pick File
      final result = await fileService.pickFile();
      if (result == null) {
        return const ImportResult(
          successCount: 0,
          errorMessage: 'Dosya seçilmedi.',
        );
      }

      final platformFile = result.files.single;
      final bytes = platformFile.bytes;
      if (bytes == null) {
        return const ImportResult(
          successCount: 0,
          errorMessage: 'Dosya okunamadı.',
        );
      }

      // Parse based on file extension
      List<List<dynamic>> rows;
      final extension = platformFile.extension?.toLowerCase() ?? '';

      if (extension == 'csv') {
        rows = fileService.parseCsv(bytes);
      } else {
        rows = fileService.parseExcel(bytes);
      }

      if (rows.isEmpty || rows.length < 2) {
        return const ImportResult(
          successCount: 0,
          errorMessage: 'Dosya boş veya geçersiz format.',
        );
      }

      // Map to Student Objects
      // Skip header (row 0) if necessary, assuming Row 0 is header
      final List<Student> newStudents = [];
      final uuid = const Uuid();
      int errorCount = 0;

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 3) {
          errorCount++;
          continue;
        }

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

      return ImportResult(
        successCount: newStudents.length,
        errorCount: errorCount,
      );
    } catch (e) {
      debugPrint('Student import error: $e');
      return ImportResult(successCount: 0, errorMessage: 'Import hatası: $e');
    }
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
