import 'dart:collection';

import '../entities/entities.dart';

class ButterflyDistributor {
  Map<String, List<ExamPlacement>> distribute({
    required List<Student> students,
    required List<ExamHall> halls,
  }) {
    final Map<String, List<ExamPlacement>> results = {}; // HallId -> Placements

    // 1. Group Students by Grade (Queues)
    final Map<String, Queue<Student>> gradeQueues = {};
    for (var s in students) {
      // Simple grade extraction (e.g., '9-A' -> '9')
      final grade = s.className.split('-').first.trim();
      if (!gradeQueues.containsKey(grade)) {
        gradeQueues[grade] = Queue<Student>();
      }
      gradeQueues[grade]!.add(s);
    }

    // Shuffle queues for randomness within grades
    for (var key in gradeQueues.keys) {
      final list = gradeQueues[key]!.toList()..shuffle();
      gradeQueues[key] = Queue.of(list);
    }

    // 2. Iterate Halls
    for (var hall in halls) {
      final List<ExamPlacement> hallPlacements = [];
      // Virtual Seat Grid construction logic could be complex,
      // but here we simplify to linear seat filling with 'neighbor' check.
      // Assuming seats are 1..capacity.

      // We need to know row/col to check 'side-by-side'.
      // Seat N (1-based) coordinates:
      // Col = (N-1) % Cols
      // Row = (N-1) / Cols

      final Map<int, String> seatGrades = {}; // SeatNo -> Grade

      for (int i = 1; i <= hall.capacity; i++) {
        // If no students left, break
        if (gradeQueues.values.every((q) => q.isEmpty)) break;

        final int col = (i - 1) % hall.columnCount;
        // final int row = (i - 1) ~/ hall.columnCount; // Enable if front-back check needed

        // Determine Ban List (Side-by-side check)
        final Set<String> bannedGrades = {};

        // Check Left Neighbor (if not first column)
        if (col > 0) {
          // Previous seat is i-1
          final leftGrade = seatGrades[i - 1];
          if (leftGrade != null) bannedGrades.add(leftGrade);
        }

        // Pick Best Candidate Grade
        // Strategy: Max remaining count, not in ban list
        String? bestGrade;
        int maxCount = -1;

        for (var grade in gradeQueues.keys) {
          if (bannedGrades.contains(grade)) continue;

          final count = gradeQueues[grade]!.length;
          if (count > maxCount && count > 0) {
            maxCount = count;
            bestGrade = grade;
          }
        }

        // If blocked (all valid grades empty), try to pick ANY valid grade even if count is low
        if (bestGrade == null) {
          // If still null, try ignoring ban list (Force placement) - Strategy B
          for (var grade in gradeQueues.keys) {
            if (gradeQueues[grade]!.isNotEmpty) {
              bestGrade = grade;
              break; // Found one
            }
          }
        }

        if (bestGrade != null && gradeQueues[bestGrade]!.isNotEmpty) {
          final student = gradeQueues[bestGrade]!.removeFirst();
          hallPlacements.add(
            ExamPlacement(
              hallId: hall.id,
              studentId: student.id,
              seatNumber: i,
            ),
          );
          seatGrades[i] = bestGrade;
        }
      }

      results[hall.id] = hallPlacements;
    }

    return results;
  }
}
