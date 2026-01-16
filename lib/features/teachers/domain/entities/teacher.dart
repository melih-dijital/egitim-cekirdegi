class Teacher {
  final String id;
  final String name;
  final String branch;
  final String schoolId;
  final List<String> availableDays; // e.g. ["Monday", "Tuesday"]

  const Teacher({
    required this.id,
    required this.name,
    required this.branch,
    this.schoolId = 'school-1', // Default for backwards compatibility
    this.availableDays = const [],
  });
}
