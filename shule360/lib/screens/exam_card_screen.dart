import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/exam_card.dart';
import '../models/student.dart';
import '../services/exam_card_service.dart';
import '../services/student_service.dart';

class ExamCardScreen extends StatefulWidget {
  final AppUser currentUser;
  final String classId;
  final String term;

  const ExamCardScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.term,
  });

  @override
  State<ExamCardScreen> createState() => _ExamCardScreenState();
}

class _ExamCardScreenState extends State<ExamCardScreen> {
  final _examCardService = ExamCardService();
  final _studentService = StudentService();
  final _examNameController = TextEditingController(text: 'End of Term Exam');

  Future<void> _issueCard(Student student) async {
    final card = await _examCardService.issueCard(
      schoolId: widget.currentUser.schoolId,
      studentId: student.id,
      examName: _examNameController.text.trim(),
      term: widget.term,
      issuedByUserId: widget.currentUser.id,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          card.feeCleared
              ? '${student.fullName}: Exam card issued (fees cleared)'
              : '${student.fullName}: Exam card issued — FEE BALANCE OUTSTANDING',
        ),
        backgroundColor: card.feeCleared ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exam Cards')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _examNameController,
              decoration: const InputDecoration(labelText: 'Exam name'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Student>>(
                stream: _studentService.watchStudentsForClass(
                  schoolId: widget.currentUser.schoolId,
                  classId: widget.classId,
                ),
                builder: (context, snapshot) {
                  final students = snapshot.data ?? [];
                  if (students.isEmpty) {
                    return const Text('No students in this class yet.');
                  }
                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(student.fullName),
                          subtitle: Text(student.admissionNumber),
                          trailing: FilledButton(
                            onPressed: () => _issueCard(student),
                            child: const Text('Issue Card'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}