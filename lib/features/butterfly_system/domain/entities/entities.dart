class Student {
  final String id;
  final String number;
  final String name;
  final String className;
  // 'sh' in database, but branch in logic
  final String branch;

  const Student({
    required this.id,
    required this.number,
    required this.name,
    required this.className,
    required this.branch,
  });
}

class ExamHall {
  final String id;
  final String name;
  final int capacity;
  final int columnCount;
  // Configuration for 'snake' layout, etc.
  final Map<String, dynamic>? config;

  const ExamHall({
    required this.id,
    required this.name,
    required this.capacity,
    this.columnCount = 4,
    this.config,
  });
}

class ExamPlacement {
  final String hallId;
  final String studentId;
  final int seatNumber;

  const ExamPlacement({
    required this.hallId,
    required this.studentId,
    required this.seatNumber,
  });
}
