import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/global_providers.dart';
import '../../../../features/teachers/presentation/providers/teacher_providers.dart';
import '../../domain/entities/duty.dart';
import '../../../../core/init/supabase_init.dart';
import '../../domain/repositories/duty_repository.dart';
import '../../data/repositories/duty_repository_impl.dart';

final dutyRepositoryProvider = Provider<DutyRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return DutyRepositoryImpl(supabase);
});

// Duty List Management
class DutyListNotifier extends StateNotifier<AsyncValue<List<Duty>>> {
  final Ref ref;
  DutyListNotifier(this.ref) : super(const AsyncValue.data([]));

  void setDuties(List<Duty> duties) {
    state = AsyncValue.data(duties);
  }

  Future<void> distributeDuties() async {
    state = const AsyncValue.loading();

    // Simulate delay
    await Future.delayed(const Duration(seconds: 1));

    final teachers = ref.read(teachersProvider);
    final distributor = ref.read(dutyDistributorProvider);

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    final result = distributor.distribute(
      startDate: start,
      endDate: end,
      teachers: teachers,
      areas: ['Okul Bahçesi', '1. Kat Koridor', '2. Kat Koridor', 'Kantin'],
      schoolId: 'school-1',
    );

    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (duties) async {
        state = AsyncValue.data(duties);
        // Save to DB
        final repo = ref.read(dutyRepositoryProvider);
        if (repo is DutyRepositoryImpl) {
          await repo.saveDuties(duties);
        }
      },
    );
  }
}

final dutyListProvider =
    StateNotifierProvider<DutyListNotifier, AsyncValue<List<Duty>>>((ref) {
      return DutyListNotifier(ref);
    });

// For backward compatibility with DutyCreationPage
class DutyCreationNotifier extends StateNotifier<AsyncValue<void>> {
  DutyCreationNotifier() : super(const AsyncValue.data(null));

  Future<void> createPlan({
    required DateTime start,
    required DateTime end,
    required List<String> areas,
  }) async {
    // This is now handled by DutyListNotifier distribution logic mainly
    // But keeping this for UI compatibility
    state = const AsyncValue.loading();
    await Future.delayed(const Duration(seconds: 1));
    state = const AsyncValue.data(null);
  }
}

final dutyCreationProvider =
    StateNotifierProvider<DutyCreationNotifier, AsyncValue<void>>((ref) {
      return DutyCreationNotifier();
    });
