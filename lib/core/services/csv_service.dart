import 'package:csv/csv.dart';
import '../../features/duty_planning/domain/entities/duty.dart';
import 'package:intl/intl.dart';

class CsvService {
  String generateDutyCsv(List<Duty> duties) {
    List<List<dynamic>> rows = [];

    // Header
    rows.add(['Tarih', 'Nöbet Yeri', 'Öğretmen']);

    // Data
    for (var duty in duties) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(duty.date),
        duty.area,
        duty.teacherName,
      ]);
    }

    // UTF-8 BOM for Excel compatibility + Semicolon delimiter for Turkish Excel
    final bom = '\uFEFF';
    final csvContent = const ListToCsvConverter(
      fieldDelimiter: ';',
    ).convert(rows);

    return '$bom$csvContent';
  }
}
