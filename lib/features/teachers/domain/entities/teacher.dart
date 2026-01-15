class Teacher {
  final String id;
  final String name;
  final String branch;
  final List<String> availableDays; // e.g. ["Monday", "Tuesday"]

  const Teacher({
    required this.id,
    required this.name,
    required this.branch,
    this.availableDays = const [],
  });
}
