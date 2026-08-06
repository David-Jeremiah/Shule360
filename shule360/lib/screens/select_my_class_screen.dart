import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../services/class_service.dart';

/// Same idea as SelectClassSubjectScreen but for flows that only ever
/// need a class — Report Cards and Mid-Term Report, neither of which
/// takes a subjectId. Kept separate rather than reusing
/// SelectClassSubjectScreen so the Continue button can never be gated on
/// a subject pick that the caller doesn't want.
class SelectClassScreen extends StatefulWidget {
  final AppUser currentUser;
  final void Function(String classId) onSelected;
  final String title;

  const SelectClassScreen({
    super.key,
    required this.currentUser,
    required this.onSelected,
    this.title = 'Select Class',
  });

  @override
  State<SelectClassScreen> createState() => _SelectClassScreenState();
}

class _SelectClassScreenState extends State<SelectClassScreen> {
  final _classService = ClassService();
  SchoolClass? _selectedClass;

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
                    value: classes.contains(_selectedClass) ? _selectedClass : null,
                    hint: const Text('Choose a class'),
                    items: classes
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (c) => setState(() => _selectedClass = c),
                  );
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _selectedClass != null
                    ? () {
                  Navigator.of(context).pop();
                  widget.onSelected(_selectedClass!.id);
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