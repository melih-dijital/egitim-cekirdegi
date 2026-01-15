import 'package:flutter_test/flutter_test.dart';
import 'package:okul_cekirdegi/features/duty_planning/domain/logic/duty_distributor.dart';
import 'package:okul_cekirdegi/features/teachers/domain/entities/teacher.dart';
import 'package:okul_cekirdegi/features/duty_planning/domain/entities/duty.dart';

void main() {
  late DutyDistributor distributor;
  late List<Teacher> teachers;
  late List<String> areas;

  setUp(() {
    distributor = DutyDistributor();
    teachers = [
      const Teacher(id: '1', name: 'T1', branch: 'Math'),
      const Teacher(id: '2', name: 'T2', branch: 'Physics'),
      const Teacher(id: '3', name: 'T3', branch: 'Bio'),
      const Teacher(id: '4', name: 'T4', branch: 'Chem'),
      const Teacher(id: '5', name: 'T5', branch: 'Lit'),
    ];
    areas = ['Area1', 'Area2'];
  });

  test('should distribute duties correctly excluding weekends', () {
    // Mon Jan 1 2024 to Sun Jan 7 2024
    // Weekdays: 1, 2, 3, 4, 5 (5 days). Weekend: 6, 7.
    final start = DateTime(2024, 1, 1);
    final end = DateTime(2024, 1, 7);

    final result = distributor.distribute(
      startDate: start,
      endDate: end,
      teachers: teachers,
      areas: areas,
      schoolId: 'school1',
    );

    expect(result.isRight(), true);

    final duties = result.getRight().toNullable()!;

    // 5 days * 2 areas = 10 duties total
    expect(duties.length, 10);

    // Check no duties on weekend
    final weekendDuties = duties.where(
      (d) =>
          d.date.weekday == DateTime.saturday ||
          d.date.weekday == DateTime.sunday,
    );
    expect(weekendDuties.isEmpty, true);
  });

  test('should not assign same teacher to multiple areas on same day', () {
    final start = DateTime(2024, 1, 1); // Monday
    final end = DateTime(2024, 1, 1); // Monday

    final result = distributor.distribute(
      startDate: start,
      endDate: end,
      teachers: teachers,
      areas: ['Area1', 'Area2', 'Area3'],
      schoolId: 'school1',
    );

    final duties = result.getRight().toNullable()!;

    // Group by teacher
    final Map<String, int> teacherAssignments = {};
    for (var duty in duties) {
      teacherAssignments[duty.teacherId] =
          (teacherAssignments[duty.teacherId] ?? 0) + 1;
    }

    // Check if any teacher has > 1 duty
    for (var count in teacherAssignments.values) {
      expect(count, lessThanOrEqualTo(1));
    }
  });
}
