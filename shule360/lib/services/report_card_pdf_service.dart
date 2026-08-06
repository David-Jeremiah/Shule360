import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_card_mark.dart';
import '../models/school.dart';
import '../models/student.dart';

/// Everything the PDF needs for one student's report card. Built by the
/// editor screen from a School, a Student, and a saved ReportCardRecord —
/// this class itself has no Firestore knowledge.
class ReportCardData {
  final Student student;
  final School school;
  final String term;
  final List<ReportCardSubjectMark> subjectMarks;
  final ReportCardComments comments;
  final String? gender;
  final String? studentPhotoUrl;
  final int? classPosition;
  final int? classSize;
  final DateTime? termEndDate;
  final DateTime? nextTermStartDate;
  final double? feesBalance;
  final List<String> componentOrder;
  final List<GradingBand> gradingScale;

  const ReportCardData({
    required this.student,
    required this.school,
    required this.term,
    required this.subjectMarks,
    this.comments = const ReportCardComments(),
    this.gender,
    this.studentPhotoUrl,
    this.classPosition,
    this.classSize,
    this.termEndDate,
    this.nextTermStartDate,
    this.feesBalance,
    this.componentOrder = const ['BOT', 'MT', 'EOT', 'HW', 'T1', 'MOT'],
    this.gradingScale = kDefaultGradingScale,
  });

  double get overallAverage => subjectMarks.isEmpty
      ? 0
      : subjectMarks.map((m) => m.average).reduce((a, b) => a + b) / subjectMarks.length;

  double get overallTotal => subjectMarks.fold(0.0, (sum, m) => sum + m.average);
}

class ReportCardPdfService {
  Future<Uint8List> buildReportCardPdf(ReportCardData data) async {
    final doc = pw.Document();

    final logo = data.school.logoUrl != null ? await _fetchImage(data.school.logoUrl!) : null;
    final photo = data.studentPhotoUrl != null ? await _fetchImage(data.studentPhotoUrl!) : null;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(data, logo, photo),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1.2),
            pw.SizedBox(height: 8),
            _buildStudentInfoRow(data),
            pw.SizedBox(height: 12),
            _buildMarksTable(data),
            pw.SizedBox(height: 6),
            _buildSummaryRow(data),
            pw.SizedBox(height: 14),
            _buildGradingScale(data),
            pw.SizedBox(height: 14),
            _buildComments(data),
            pw.SizedBox(height: 12),
            _buildFooter(data),
          ],
        ),
      ),
    );

    return doc.save();
  }

  Future<void> printReportCard(ReportCardData data) async {
    final bytes = await buildReportCardPdf(data);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<pw.ImageProvider?> _fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return pw.MemoryImage(response.bodyBytes);
    } catch (_) {
      // A broken logo/photo link shouldn't block printing the report card —
      // just render without it.
    }
    return null;
  }

  pw.Widget _buildHeader(ReportCardData data, pw.ImageProvider? logo, pw.ImageProvider? photo) {
    final school = data.school;
    final phone = (school.phoneNumbers != null && school.phoneNumbers!.isNotEmpty)
        ? school.phoneNumbers!.first
        : null;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[
          pw.Container(width: 46, height: 46, child: pw.Image(logo)),
          pw.SizedBox(width: 10),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(school.name.toUpperCase(),
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (school.address != null && school.address!.isNotEmpty)
                pw.Text(school.address!, style: const pw.TextStyle(fontSize: 9)),
              if (phone != null || school.email != null)
                pw.Text(
                  [
                    if (phone != null) 'Tel: $phone',
                    if (school.email != null) 'Email: ${school.email}',
                  ].join('   '),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              pw.SizedBox(height: 4),
              pw.Text('${data.term.toUpperCase()} REPORT CARD',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              if (school.motto != null && school.motto!.isNotEmpty)
                pw.Text('"${school.motto}"',
                    style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
            ],
          ),
        ),
        if (photo != null)
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Image(photo, fit: pw.BoxFit.cover),
          )
        else
          pw.SizedBox(width: 60),
      ],
    );
  }

  pw.Widget _buildStudentInfoRow(ReportCardData data) {
    final s = data.student;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text('Name: ${s.fullName}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(child: pw.Text('Reg No: ${s.admissionNumber}')),
          if (data.gender != null) pw.Text('Gender: ${data.gender}'),
        ]),
        pw.SizedBox(height: 4),
        pw.Row(children: [
          pw.Expanded(child: pw.Text('Roll No: ${s.rollNumber}')),
          if (data.classPosition != null)
            pw.Text('Position: ${_ordinal(data.classPosition!)} out of ${data.classSize ?? '-'}'),
        ]),
      ],
    );
  }

  pw.Widget _buildMarksTable(ReportCardData data) {
    final headers = ['Subject', ...data.componentOrder, 'AVG', 'GRADE', 'COMMENT', 'INITIAL'];
    final colWidths = <int, pw.TableColumnWidth>{
      0: const pw.FlexColumnWidth(2.4),
      for (var i = 1; i <= data.componentOrder.length; i++) i: const pw.FlexColumnWidth(0.9),
    };
    final base = data.componentOrder.length + 1;
    colWidths[base] = const pw.FlexColumnWidth(0.9); // AVG
    colWidths[base + 1] = const pw.FlexColumnWidth(0.9); // GRADE
    colWidths[base + 2] = const pw.FlexColumnWidth(2.2); // COMMENT
    colWidths[base + 3] = const pw.FlexColumnWidth(0.9); // INITIAL

    return pw.Table(
      border: pw.TableBorder.all(width: 0.6),
      columnWidths: colWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers
              .map((h) => pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          ))
              .toList(),
        ),
        for (final m in data.subjectMarks)
          pw.TableRow(children: [
            _cell(m.subjectName, bold: true), // always the resolved name, never subjectId
            for (final c in data.componentOrder) _cell(m.componentScores[c]?.toStringAsFixed(0) ?? '-'),
            _cell(m.average.toStringAsFixed(1)),
            _cell(gradeFor(m.average, data.gradingScale).grade),
            _cell(m.comment ?? gradeFor(m.average, data.gradingScale).descriptor),
            _cell(m.teacherInitials ?? '-'),
          ]),
      ],
    );
  }

  pw.Widget _cell(String text, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
    ),
  );

  pw.Widget _buildSummaryRow(ReportCardData data) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('AVERAGE: ${data.overallAverage.toStringAsFixed(1)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.Text('TOTAL: ${data.overallTotal.toStringAsFixed(0)}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildGradingScale(ReportCardData data) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('GRADING SCALE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(width: 0.5),
          children: [
            pw.TableRow(children: data.gradingScale.map((b) => _cell(b.grade, bold: true)).toList()),
            pw.TableRow(children: data.gradingScale.map((b) => _cell('${b.minScore}-${b.maxScore}')).toList()),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildComments(ReportCardData data) {
    pw.Widget row(String label, String? comment) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(comment ?? '', style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text('Signature: ________________________', style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        row("Class Teacher's Comment", data.comments.classTeacherComment),
        row('Conduct Comment', data.comments.conductComment),
        row("Head Teacher's Comment", data.comments.headTeacherComment),
      ],
    );
  }

  pw.Widget _buildFooter(ReportCardData data) {
    String fmt(DateTime? d) =>
        d == null ? '____________' : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(thickness: 0.6),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('This term ends on: ${fmt(data.termEndDate)}', style: const pw.TextStyle(fontSize: 9)),
            pw.Text('Next term begins on: ${fmt(data.nextTermStartDate)}', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
        if (data.feesBalance != null) ...[
          pw.SizedBox(height: 6),
          pw.Text('Fees Balance: ${data.feesBalance!.toStringAsFixed(0)}/=',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ],
        pw.SizedBox(height: 6),
        pw.Text('This report is invalid without the school stamp.',
            style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.red)),
      ],
    );
  }

  String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }
}