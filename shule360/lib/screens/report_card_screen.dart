import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../widgets/school_shell.dart';
import 'report_card_editor_screen.dart';

/// Entry point is class-only, same as before — this never asks for a
/// subject. Subjects are chosen per student inside the editor, since a
/// report card covers every subject a student takes, not one at a time.
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

    return SchoolScaffold(
      currentUser: currentUser,
      pageTitle: 'Report Cards',
      term: term,
      body: StreamBuilder<List<Student>>(
        stream: studentService.watchStudentsForClass(schoolId: currentUser.schoolId, classId: classId),
        builder: (context, snapshot) {
          final students = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (students.isEmpty) {
            return const Text(
              'No students in this class yet.',
              style: TextStyle(fontStyle: FontStyle.italic),
            );
          }
          final sorted = [...students]..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sorted
                .map((student) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(student.fullName),
                subtitle: Text('Admission: ${student.admissionNumber} · Roll: ${student.rollNumber}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportCardEditorScreen(
                      currentUser: currentUser,
                      student: student,
                      classId: classId,
                      term: term,
                    ),
                  ),
                ),
              ),
            ))
                .toList(),
          );
        },
      ),
    );
  }
}