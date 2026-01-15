import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'dart:convert';

class FileService {
  Future<FilePickerResult?> pickFile() async {
    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
  }

  List<List<dynamic>> parseExcel(Uint8List bytes) {
    var excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];

    final table = excel.tables[excel.tables.keys.first];
    if (table == null) return [];

    List<List<dynamic>> rows = [];
    // Skip maxCols check for now, just map
    for (var row in table.rows) {
      if (row.isEmpty) continue;
      rows.add(row.map((cell) => cell?.value).toList());
    }
    return rows;
  }

  List<List<dynamic>> parseCsv(Uint8List bytes) {
    // Decode bytes to string
    final content = utf8.decode(bytes);
    // Detect delimiter (simple check)
    final delimiter = content.contains(';') ? ';' : ',';
    return CsvToListConverter(fieldDelimiter: delimiter).convert(content);
  }
}
