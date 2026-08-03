import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/mark_record.dart';
import '../models/student.dart';
import '../services/marks_service.dart';
import '../services/report_card_pdf_service.dart';
import '../services/student_service.dart';

class ReportCardScreen extends StatelessWidget {
  final AppUser currentUser;
  final String classId;
  final String term;

  const ReportCardScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.term,
  });

  @override
  Widget build(BuildContext context) {
    final studentService = StudentService();
    final marksService = MarksService();
    final pdfService = ReportCardPdfService();

    return Scaffold(
      appBar: AppBar(title: const Text('Report Cards')),
      body: StreamBuilder<List<Student>>(
        stream: studentService.watchStudentsForClass(
          schoolId: currentUser.schoolId,
          classId: classId,
        ),
        builder: (context, studentSnapshot) {
          final students = studentSnapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('No students in this class yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text('${student.fullName} (${student.admissionNumber})'),
                  children: [
                    StreamBuilder<List<MarkRecord>>(
                      stream: marksService.watchMarksForStudent(
                        schoolId: currentUser.schoolId,
                        studentId: student.id,
                        term: term,
                      ),
                      builder: (context, marksSnapshot) {
                        final marks = marksSnapshot.data ?? [];
                        if (marks.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No marks entered yet.'),
                          );
                        }
                        final average =
                            marks.map((m) => m.percentage).reduce((a, b) => a + b) / marks.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...marks.map((m) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subject: ${m.subjectId}'),
                                    Text('${m.score}/${m.maxScore} (${m.percentage.toStringAsFixed(1)}%)'),
                                  ],
                                ),
                              )),
                              const Divider(),
                              Text('Average: ${average.toStringAsFixed(1)}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                icon: const Icon(Icons.print),
                                label: const Text('Print Report Card'),
                                onPressed: () => pdfService.printReportCard(
                                  student: student,
                                  marks: marks,
                                  schoolName: 'Shule360 Test School', // TODO: pull from School model once school profile UI exists
                                  term: term,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}