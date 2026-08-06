import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../services/class_service.dart';

class SelectClassSubjectScreen extends StatefulWidget {
  final AppUser currentUser;
  final void Function(String classId, String subjectId) onSelected;
  final String title;

  /// When set, only subjects with this departmentName show up — used so
  /// an HOD only sees their own department's subjects.
  final String? departmentFilter;

  /// When set, only subjects whose id is in this list show up — used so
  /// a teacher only sees the subjects THEY were assigned, not every
  /// subject in the school.
  final List<String>? allowedSubjectIds;

  const SelectClassSubjectScreen({
    super.key,
    required this.currentUser,
    required this.onSelected,
    this.title = 'Select Class & Subject',
    this.departmentFilter,
    this.allowedSubjectIds,
  });

  @override
  State<SelectClassSubjectScreen> createState() => _SelectClassSubjectScreenState();
}

class _SelectClassSubjectScreenState extends State<SelectClassSubjectScreen> {
  final _classService = ClassService();
  SchoolClass? _selectedClass;
  Subject? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    final baseStream = widget.departmentFilter != null
        ? _classService.watchDepartmentSubjects(
      schoolId: widget.currentUser.schoolId,
      departmentName: widget.departmentFilter!,
    )
        : _classService.watchSubjects(widget.currentUser.schoolId);

    final subjectsStream = widget.allowedSubjectIds != null
        ? baseStream.map((subjects) =>
        subjects.where((s) => widget.allowedSubjectIds!.contains(s.id)).toList())
        : baseStream;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Class', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<List<SchoolClass>>(
                stream: _classService.watchClasses(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final classes = snapshot.data ?? [];
                  if (classes.isEmpty) {
                    return const Text('No classes yet — create one first.');
                  }
                  return DropdownButton<SchoolClass>(
                    isExpanded: true,
                    value: classes.contains(_selectedClass) ? _selectedClass : null,
                    hint: const Text('Choose a class'),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _selectedClass = c),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Subject', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              StreamBuilder<List<Subject>>(
                stream: subjectsStream,
                builder: (context, snapshot) {
                  final subjects = snapshot.data ?? [];
                  if (subjects.isEmpty) {
                    return Text(
                      widget.allowedSubjectIds != null
                          ? 'You have no subjects assigned yet — ask your admin.'
                          : (widget.departmentFilter != null
                          ? 'No subjects assigned to your department yet — ask your admin.'
                          : 'No subjects yet — create one first.'),
                    );
                  }
                  return DropdownButton<Subject>(
                    isExpanded: true,
                    value: subjects.contains(_selectedSubject) ? _selectedSubject : null,
                    hint: const Text('Choose a subject'),
                    items: subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (s) => setState(() => _selectedSubject = s),
                  );
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: (_selectedClass != null && _selectedSubject != null)
                    ? () {
                  Navigator.of(context).pop();
                  widget.onSelected(_selectedClass!.id, _selectedSubject!.id);
                }
                    : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}