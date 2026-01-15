import 'package:flutter_test/flutter_test.dart';
import 'package:okul_cekirdegi/features/butterfly_system/domain/logic/butterfly_distributor.dart';
import 'package:okul_cekirdegi/features/butterfly_system/domain/entities/entities.dart';

void main() {
  late ButterflyDistributor distributor;
  late List<Student> students;
  late List<ExamHall> halls;

  setUp(() {
    distributor = ButterflyDistributor();

    // Create students: 10 from 9th grade, 10 from 10th grade
    students = [];
    for (int i = 0; i < 10; i++) {
      students.add(
        Student(
          id: '9-$i',
          number: '10$i',
          name: 'S9-$i',
          className: '9-A',
          branch: 'A',
        ),
      );
    }
    for (int i = 0; i < 10; i++) {
      students.add(
        Student(
          id: '10-$i',
          number: '20$i',
          name: 'S10-$i',
          className: '10-A',
          branch: 'A',
        ),
      );
    }

    // Create 1 Hall with capacity 20, 4 columns
    halls = [
      const ExamHall(
        id: 'h1',
        name: 'Hall 1',
        capacity: 20,
        columnCount: 2,
      ), // 2 columns to force neighbors easily
    ];
  });

  test('should distribute students without side-by-side conflict', () {
    // Total students 20, Hall Cap 20. Should fill.
    final result = distributor.distribute(students: students, halls: halls);

    expect(result.containsKey('h1'), true);
    final placements = result['h1']!;

    expect(placements.length, 20);

    // Sort by seat number to check neighbors
    placements.sort((a, b) => a.seatNumber.compareTo(b.seatNumber));

    // Map seat to student grade
    String getGrade(String studentId) {
      final s = students.firstWhere((st) => st.id == studentId);
      return s.className.split('-').first;
    }

    int conflicts = 0;

    // Check neighbors
    // Col count 2.
    // Seat 1 (Row 0, Col 0) -> Neighbor Seat 2 (Row 0, Col 1)
    // Seat 3 (Row 1, Col 0) -> Neighbor Seat 4 (Row 1, Col 1)
    for (int i = 0; i < placements.length; i++) {
      final current = placements[i];

      // If current is NOT in first column (col > 0), check previous (left)
      // Seat numbers are 1-based.
      // Col index = (seat - 1) % colCount.
      int colIndex = (current.seatNumber - 1) % 2;

      if (colIndex > 0) {
        // Has left neighbor
        final leftSeatNum = current.seatNumber - 1;
        final left = placements.firstWhere((p) => p.seatNumber == leftSeatNum);

        if (getGrade(current.studentId) == getGrade(left.studentId)) {
          conflicts++;
          print(
            'Conflict at seat ${current.seatNumber} and ${left.seatNumber}',
          );
        }
      }
    }

    expect(
      conflicts,
      0,
      reason: 'Students from same grade should not sit side-by-side',
    );
  });
}
