import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

import '../../features/duty_planning/domain/entities/duty.dart';

class PdfService {
  Future<void> printDutyPlan(List<Duty> duties, String title) async {
    final pdfBytes = await _generateDutyPdf(duties, title);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'nobet_cizelgesi.pdf',
    );
  }

  Future<void> shareDutyPlan(List<Duty> duties, String title) async {
    final pdfBytes = await _generateDutyPdf(duties, title);

    await Printing.sharePdf(bytes: pdfBytes, filename: 'nobet_cizelgesi.pdf');
  }

  Future<Uint8List> _generateDutyPdf(List<Duty> duties, String title) async {
    final doc = pw.Document();

    // Load font for Turkish support
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(title, style: pw.TextStyle(font: boldFont, fontSize: 20)),
            pw.Text(
              'Oluşturma: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
              style: pw.TextStyle(font: font, fontSize: 10),
            ),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Okul Asistanı',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
            pw.Text(
              'Sayfa ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 8),
            ),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            border: pw.TableBorder.all(color: PdfColors.grey400),
            headerStyle: pw.TextStyle(
              font: boldFont,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            cellStyle: pw.TextStyle(font: font),
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
            },
            headers: <String>['Tarih', 'Nöbet Yeri', 'Öğretmen'],
            data: duties
                .map(
                  (d) => [
                    DateFormat('dd.MM.yyyy (EEEE)', 'tr_TR').format(d.date),
                    d.area,
                    d.teacherName,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
