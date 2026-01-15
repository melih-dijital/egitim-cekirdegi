import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DutyResultRow extends StatelessWidget {
  final String date;
  final String dutyArea;
  final String teacherName;
  final bool isAlt;

  const DutyResultRow({
    super.key,
    required this.date,
    required this.dutyArea,
    required this.teacherName,
    this.isAlt = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isAlt
          ? AppColors.surfaceVariant.withValues(alpha: 0.5)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              date,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              dutyArea,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              teacherName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
