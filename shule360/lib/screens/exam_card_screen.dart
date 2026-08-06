import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/exam_card.dart';
import '../models/school.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../services/class_service.dart';
import '../services/exam_card_service.dart';
import '../services/school_service.dart';
import '../services/student_service.dart';
import '../widgets/school_shell.dart';

class ExamCardScreen extends StatefulWidget {
  final AppUser currentUser;
  final String term;

  const ExamCardScreen({
    super.key,
    required this.currentUser,
    required this.term,
  });

  @override
  State<ExamCardScreen> createState() => _ExamCardScreenState();
}

class _ExamCardScreenState extends State<ExamCardScreen> {
  final _examCardService = ExamCardService();
  final _studentService = StudentService();
  final _classService = ClassService();
  final _schoolService = SchoolService();

  // All streams are created ONCE in initState and cached — never inside
  // build(). Recreating Firestore streams on every rebuild is what causes
  // the native-channel churn that crashes the Windows build.
  late final Stream<School> _schoolStream;
  late final Stream<List<SchoolClass>> _classesStream;

  SchoolClass? _selectedClass;
  String? _streamedClassId;
  Stream<List<Student>>? _studentsStream;

  // 'BOT' = Beginning of Term, 'EOT' = End of Term. No subject involved —
  // an exam card just needs which sitting it's for.
  String _examType = 'EOT';

  @override
  void initState() {
    super.initState();
    _schoolStream = _schoolService.watchSchool(widget.currentUser.schoolId);
    _classesStream = _classService.watchClasses(widget.currentUser.schoolId);
  }

  void _onClassChanged(SchoolClass? c) {
    setState(() {
      _selectedClass = c;
      if (c != null && c.id != _streamedClassId) {
        _streamedClassId = c.id;
        _studentsStream = _studentService.watchStudentsForClass(
          schoolId: widget.currentUser.schoolId,
          classId: c.id,
        );
      }
    });
  }

  Future<void> _issueAndPreview(Student student, School? school) async {
    try {
      final card = await _examCardService.issueCard(
        schoolId: widget.currentUser.schoolId,
        studentId: student.id,
        examName: _examType == 'BOT' ? 'Beginning of Term' : 'End of Term',
        term: widget.term,
        issuedByUserId: widget.currentUser.id,
      );
      if (!mounted) return;
      await _showCardPreview(card, student, school);
    } on FeeNotClearedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not issue card: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showCardPreview(ExamCard card, Student student, School? school) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exam Card'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (school != null) ...[
                Row(
                  children: [
                    if (school.logoUrl != null)
                      CircleAvatar(radius: 20, backgroundImage: NetworkImage(school.logoUrl!)),
                    if (school.logoUrl != null) const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        school.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (school.address != null && school.address!.isNotEmpty)
                  Text(school.address!, style: Theme.of(context).textTheme.bodySmall),
                const Divider(height: 24),
              ],
              Text(student.fullName, style: Theme.of(context).textTheme.titleMedium),
              Text('Admission: ${student.admissionNumber}'),
              Text('Roll No: ${student.rollNumber}'),
              const SizedBox(height: 8),
              Text('${card.examName} — ${card.term}'),
              const SizedBox(height: 4),
              Text(
                'Fees: Cleared',
                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          FilledButton.icon(
            onPressed: () {
              // TODO: wire up an actual printing package (e.g. `printing`)
              // here once one is added to the project. For now this just
              // confirms the card is ready.
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.fullName}\'s card sent to printer')),
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<School>(
      stream: _schoolStream,
      builder: (context, schoolSnap) {
        final school = schoolSnap.data;

        return SchoolScaffold(
          currentUser: widget.currentUser,
          pageTitle: 'Exam Cards',
          body: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (school != null) ...[
                  Row(
                    children: [
                      if (school.logoUrl != null) ...[
                        CircleAvatar(radius: 18, backgroundImage: NetworkImage(school.logoUrl!)),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Text(school.name, style: Theme.of(context).textTheme.titleLarge),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Term: ${widget.term}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 20),
                ],

                Text('Exam Type', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Beginning of Term (BOT)'),
                      selected: _examType == 'BOT',
                      onSelected: (_) => setState(() => _examType = 'BOT'),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('End of Term (EOT)'),
                      selected: _examType == 'EOT',
                      onSelected: (_) => setState(() => _examType = 'EOT'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Text('Class', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                StreamBuilder<List<SchoolClass>>(
                  stream: _classesStream,
                  builder: (context, snap) {
                    final classes = snap.data ?? [];
                    if (classes.isEmpty) {
                      return const Text(
                        'No classes exist yet — create one under Manage Classes & Subjects first.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      );
                    }
                    final current = classes.contains(_selectedClass) ? _selectedClass : null;
                    return DropdownButtonFormField<SchoolClass>(
                      initialValue: current,
                      decoration: const InputDecoration(labelText: 'Select class'),
                      items: classes
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                          .toList(),
                      onChanged: _onClassChanged,
                    );
                  },
                ),

                const SizedBox(height: 24),

                if (_selectedClass != null && _studentsStream != null)
                  StreamBuilder<List<Student>>(
                    stream: _studentsStream,
                    builder: (context, snap) {
                      final students = snap.data ?? [];
                      if (students.isEmpty) {
                        return const Text('No students in this class yet.');
                      }
                      final sorted = [...students]..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
                      return Column(
                        children: sorted
                            .map((student) => _StudentCardRow(
                          key: ValueKey(student.id),
                          student: student,
                          examCardService: _examCardService,
                          schoolId: widget.currentUser.schoolId,
                          term: widget.term,
                          onPrint: (s) => _issueAndPreview(s, school),
                        ))
                            .toList(),
                      );
                    },
                  )
                else
                  const Text(
                    'Choose a class above to see students and issue exam cards.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One student row that checks its own fee-clearance status and enables
/// the print button only when fees are cleared for the term.
class _StudentCardRow extends StatefulWidget {
  final Student student;
  final ExamCardService examCardService;
  final String schoolId;
  final String term;
  final ValueChanged<Student> onPrint;

  const _StudentCardRow({
    super.key,
    required this.student,
    required this.examCardService,
    required this.schoolId,
    required this.term,
    required this.onPrint,
  });

  @override
  State<_StudentCardRow> createState() => _StudentCardRowState();
}

class _StudentCardRowState extends State<_StudentCardRow> {
  late final Future<bool> _clearedFuture;

  @override
  void initState() {
    super.initState();
    _clearedFuture = widget.examCardService.checkFeeCleared(
      schoolId: widget.schoolId,
      studentId: widget.student.id,
      term: widget.term,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _clearedFuture,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final cleared = snap.data ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(widget.student.fullName),
            subtitle: Text('Admission: ${widget.student.admissionNumber}'),
            trailing: loading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(cleared ? 'Cleared' : 'Balance due'),
                  backgroundColor: cleared
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: cleared ? Colors.green.shade800 : Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: cleared ? () => widget.onPrint(widget.student) : null,
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}