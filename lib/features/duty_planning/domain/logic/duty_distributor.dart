import 'dart:math';

import 'package:uuid/uuid.dart';

import 'package:okul_cekirdegi/features/duty_planning/domain/entities/duty.dart';
import 'package:okul_cekirdegi/features/teachers/domain/entities/teacher.dart';
import '../../../../core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

class DutyDistributor {
  final _uuid = const Uuid();

  Either<Failure, List<Duty>> distribute({
    required DateTime startDate,
    required DateTime endDate,
    required List<Teacher> teachers,
    required List<String> areas,
    required String schoolId,
  }) {
    try {
      final List<Duty> plan = [];
      final Map<String, int> dutyCounts = {for (var t in teachers) t.id: 0};
      final Map<String, String?> lastArea = {
        for (var t in teachers) t.id: null,
      };

      // Loop through each day
      for (
        var day = startDate;
        day.isBefore(endDate.add(const Duration(days: 1)));
        day = day.add(const Duration(days: 1))
      ) {
        // Skip weekends
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          continue;
        }

        final List<String> dailyAssignedTeachers = [];
        // Shuffle areas to avoid bias
        final shuffledAreas = List<String>.from(areas)..shuffle();

        for (final area in shuffledAreas) {
          // 1. Candidate Pool
          var candidates = teachers.where((t) {
            // Check if already assigned today
            if (dailyAssignedTeachers.contains(t.id)) return false;

            // Check constraints (e.g. availability - simplified here)
            // In a real app, we would check t.availableDays against day.weekday
            return true;
          }).toList();

          if (candidates.isEmpty) {
            // No candidates left for this area on this day
            // In a real app, we might want to return a specific warning or partial plan
            continue;
          }

          // 2. Scoring (Weighted Greedy)
          final Map<String, int> scores = {};

          for (final teacher in candidates) {
            int score = 0;

            // Criterion A: Total Duty Count (Less is better)
            // Max potential score 10000. Each existing duty penalizes score.
            score += (100 - (dutyCounts[teacher.id] ?? 0)) * 10;

            // Criterion B: Consecutive Area (Variety)
            if (lastArea[teacher.id] == area) {
              score -= 500; // Big penalty for same area
            }

            // Criterion C: Randomness for tie-breaking
            score += Random().nextInt(5);

            scores[teacher.id] = score;
          }

          // 3. Selection
          candidates.sort(
            (a, b) => (scores[b.id] ?? 0).compareTo(scores[a.id] ?? 0),
          );
          final selectedTeacher = candidates.first;

          // 4. Assignment
          final duty = Duty(
            id: _uuid.v4(),
            schoolId: schoolId,
            date: day,
            area: area,
            teacherId: selectedTeacher.id,
            teacherName: selectedTeacher.name,
          );

          plan.add(duty);
          dutyCounts[selectedTeacher.id] =
              (dutyCounts[selectedTeacher.id] ?? 0) + 1;
          lastArea[selectedTeacher.id] = area;
          dailyAssignedTeachers.add(selectedTeacher.id);
        }
      }

      return right(plan);
    } catch (e) {
      return left(ServerFailure('Dağıtım hatası: $e'));
    }
  }
}
