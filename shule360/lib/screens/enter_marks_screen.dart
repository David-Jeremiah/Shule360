import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/mark_record.dart';
import '../models/student.dart';
import '../services/marks_service.dart';
import '../services/student_service.dart';

class EnterMarksScreen extends StatefulWidget {
  final AppUser currentUser;
  final String classId;
  final String subjectId;
  final String term;

  const EnterMarksScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.subjectId,
    required this.term,
  });

  @override
  State<EnterMarksScreen> createState() => _EnterMarksScreenState();
}

class _EnterMarksScreenState extends State<EnterMarksScreen> {
  final _studentService = StudentService();
  final _marksService = MarksService();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  TextEditingController _controllerFor(String studentId) {
    return _controllers.putIfAbsent(studentId, () => TextEditingController());
  }

  Future<void> _saveMark(Student student, TermPeriod period) async {
    final text = _controllerFor(student.id).text.trim();
    if (text.isEmpty) return;
    final score = double.tryParse(text);
    if (score == null) return;

    setState(() => _isSaving = true);
    try {
      final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
      await _marksService.submitMark(MarkRecord(
        id: id,
        schoolId: widget.currentUser.schoolId,
        studentId: student.id,
        subjectId: widget.subjectId,
        classId: widget.classId,
        term: widget.term,
        period: period,
        score: score,
        maxScore: 100,
        enteredByUserId: widget.currentUser.id,
        enteredAt: DateTime.now(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved ${student.fullName}: $score')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Marks')),
      body: StreamBuilder<List<Student>>(
        stream: _studentService.watchStudentsForClass(
          schoolId: widget.currentUser.schoolId,
          classId: widget.classId,
        ),
        builder: (context, snapshot) {
          final students = snapshot.data ?? [];
          if (students.isEmpty) {
            return const Center(child: Text('No students registered in this class yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('${student.fullName} (${student.admissionNumber})'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controllerFor(student.id),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Score / 100'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton.filled(
                        onPressed: _isSaving
                            ? null
                            : () => _saveMark(student, TermPeriod.endOfTerm),
                        icon: const Icon(Icons.save),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}