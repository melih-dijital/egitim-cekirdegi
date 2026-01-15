import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/init/supabase_init.dart';
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../../data/repositories/teacher_repository_impl.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return TeacherRepositoryImpl(supabase);
});

class TeachersNotifier extends StateNotifier<List<Teacher>> {
  final TeacherRepository _repository;

  TeachersNotifier(this._repository) : super([]) {
    // Initial fetch, hardcoded school-id for now or fetch from Auth User
    fetchTeachers('school-1');
  }

  Future<void> fetchTeachers(String schoolId) async {
    final result = await _repository.getTeachers(schoolId);
    result.fold(
      (failure) => state = [], // Handle error state properly in real app
      (teachers) => state = teachers,
    );
  }

  Future<void> addTeacher(Teacher teacher) async {
    final result = await _repository.addTeacher(teacher);
    result.fold(
      (failure) => null, // Show error
      (_) => state = [...state, teacher], // Optimistic update
    );
  }
}

final teachersProvider = StateNotifierProvider<TeachersNotifier, List<Teacher>>(
  (ref) {
    final repo = ref.watch(teacherRepositoryProvider);
    return TeachersNotifier(repo);
  },
);
