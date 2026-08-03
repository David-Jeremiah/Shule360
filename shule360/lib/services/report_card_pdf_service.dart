import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/mark_record.dart';
import '../models/student.dart';

class ReportCardPdfService {
  Future<Uint8List> buildReportCardPdf({
    required Student student,
    required List<MarkRecord> marks,
    required String schoolName,
    required String term,
  }) async {
    final doc = pw.Document();
    final average = marks.isEmpty
        ? 0.0
        : marks.map((m) => m.percentage).reduce((a, b) => a + b) / marks.length;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(schoolName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Report Card — $term', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 16),
              pw.Text('Name: ${student.fullName}'),
              pw.Text('Admission No: ${student.admissionNumber}'),
              pw.Text('Class: ${student.classId}'),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Subject')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Score')),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('%')),
                    ],
                  ),
                  ...marks.map((m) => pw.TableRow(children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(m.subjectId)),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text('${m.score}/${m.maxScore}')),
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(m.percentage.toStringAsFixed(1))),
                  ])),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text('Average: ${average.toStringAsFixed(1)}%',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Class Teacher: ____________________'),
                  pw.Text('Head Teacher: ____________________'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> printReportCard({
    required Student student,
    required List<MarkRecord> marks,
    required String schoolName,
    required String term,
  }) async {
    final bytes = await buildReportCardPdf(
      student: student,
      marks: marks,
      schoolName: schoolName,
      term: term,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}