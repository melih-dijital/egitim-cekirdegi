import '../../domain/entities/duty.dart';

class DutyModel extends Duty {
  const DutyModel({
    required super.id,
    required super.schoolId,
    required super.date,
    required super.area,
    required super.teacherId,
    required super.teacherName,
  });

  factory DutyModel.fromJson(Map<String, dynamic> json) {
    return DutyModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      date: DateTime.parse(json['date'] as String),
      area: json['area'] as String,
      teacherId: json['teacher_id'] as String,
      teacherName: json['teachers'] != null
          ? json['teachers']['name'] as String
          : 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'date': date.toIso8601String(),
      'area': area,
      'teacher_id': teacherId,
    };
  }
}
