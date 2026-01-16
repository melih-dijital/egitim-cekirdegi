import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/init/supabase_init.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../data/repositories/teacher_repository_impl.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return TeacherRepositoryImpl(supabase);
});

/// Tracks the last error for display in UI
final teacherErrorProvider = StateProvider<String?>((ref) => null);

class TeachersNotifier extends StateNotifier<List<Teacher>> {
  final TeacherRepository _repository;
  final Ref _ref;

  TeachersNotifier(this._repository, this._ref) : super([]) {
    // Initial fetch, hardcoded school-id for now or fetch from Auth User
    fetchTeachers('school-1');
  }

  Future<void> fetchTeachers(String schoolId) async {
    final result = await _repository.getTeachers(schoolId);
    result.fold(
      (failure) {
        debugPrint('Failed to fetch teachers: ${failure.message}');
        _ref.read(teacherErrorProvider.notifier).state = failure.message;
        state = [];
      },
      (teachers) {
        _ref.read(teacherErrorProvider.notifier).state = null;
        state = teachers;
      },
    );
  }

  Future<bool> addTeacher(Teacher teacher) async {
    debugPrint(
      'Adding teacher: ${teacher.name}, schoolId: ${teacher.schoolId}',
    );
    final result = await _repository.addTeacher(teacher);
    return result.fold(
      (failure) {
        debugPrint('Failed to add teacher: ${failure.message}');
        _ref.read(teacherErrorProvider.notifier).state =
            'Ekleme hatası: ${failure.message}';
        return false;
      },
      (_) {
        debugPrint('Teacher added successfully: ${teacher.name}');
        _ref.read(teacherErrorProvider.notifier).state = null;
        state = [...state, teacher];
        return true;
      },
    );
  }
}

final teachersProvider = StateNotifierProvider<TeachersNotifier, List<Teacher>>(
  (ref) {
    final repo = ref.watch(teacherRepositoryProvider);
    return TeachersNotifier(repo, ref);
  },
);
