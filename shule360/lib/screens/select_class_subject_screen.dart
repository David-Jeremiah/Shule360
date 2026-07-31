import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../services/class_service.dart';

/// A simple picker screen — lets the user choose a class and subject
/// before continuing to a screen that needs both (marks entry, fees).
/// [onSelected] is called with (classId, subjectId) once both are chosen.
class SelectClassSubjectScreen extends StatefulWidget {
  final AppUser currentUser;
  final void Function(String classId, String subjectId) onSelected;
  final String title;

  const SelectClassSubjectScreen({
    super.key,
    required this.currentUser,
    required this.onSelected,
    this.title = 'Select Class & Subject',
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
                    value: _selectedClass,
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
                stream: _classService.watchSubjects(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final subjects = snapshot.data ?? [];
                  if (subjects.isEmpty) {
                    return const Text('No subjects yet — create one first.');
                  }
                  return DropdownButton<Subject>(
                    isExpanded: true,
                    value: _selectedSubject,
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