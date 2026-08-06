import 'package:flutter/material.dart';
import '../constants/uganda_class_levels.dart';
import '../constants/uganda_subjects.dart';
import '../models/app_user.dart';
import '../models/school.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../services/class_service.dart';
import '../services/school_service.dart';
import '../widgets/sign_out_button.dart';

class ManageClassesScreen extends StatefulWidget {
  final AppUser currentUser;

  const ManageClassesScreen({super.key, required this.currentUser});

  @override
  State<ManageClassesScreen> createState() => _ManageClassesScreenState();
}

class _ManageClassesScreenState extends State<ManageClassesScreen> {
  final _classService = ClassService();
  final _classNameController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _streamInputController = TextEditingController();
  bool _isSavingClass = false;
  bool _isSavingSubject = false;
  bool _useStreams = false;
  final List<String> _streamNames = [];
  bool _isGenerating = false;

  Future<void> _addClassManual() async {
    final name = _classNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSavingClass = true);
    try {
      await _classService.createClass(SchoolClass(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        schoolId: widget.currentUser.schoolId,
        name: name,
        levelLabel: name,
      ));
      _classNameController.clear();
    } finally {
      if (mounted) setState(() => _isSavingClass = false);
    }
  }

  Future<void> _addSubject() async {
    final name = _subjectNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSavingSubject = true);
    try {
      await _classService.createSubjectIfNotExists(Subject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        schoolId: widget.currentUser.schoolId,
        name: name,
        levelScope: EducationLevelScope.both,
      ));
      _subjectNameController.clear();
    } finally {
      if (mounted) setState(() => _isSavingSubject = false);
    }
  }

  void _addStreamName() {
    final name = _streamInputController.text.trim();
    if (name.isEmpty || _streamNames.contains(name)) return;
    setState(() {
      _streamNames.add(name);
      _streamInputController.clear();
    });
  }

  Future<void> _generateClasses(List<String> levels) async {
    setState(() => _isGenerating = true);
    try {
      final count = await _classService.generateClasses(
        schoolId: widget.currentUser.schoolId,
        levelLabels: levels,
        streamNames: _useStreams ? _streamNames : const [],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count classes created')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Classes & Subjects'), actions: const [SignOutButton()]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildClassesColumn()),
              const SizedBox(width: 32),
              Expanded(child: _buildSubjectsColumn()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassesColumn() {
    return FutureBuilder<School>(
      future: SchoolService().fetchSchool(widget.currentUser.schoolId),
      builder: (context, schoolSnapshot) {
        final level = schoolSnapshot.data?.level;
        final levelOptions = level == SchoolLevel.primary
            ? UgandaClassLevels.primary
            : level == SchoolLevel.secondary
            ? UgandaClassLevels.secondary
            : [...UgandaClassLevels.primary, ...UgandaClassLevels.secondary];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Classes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _classNameController,
                    decoration: const InputDecoration(hintText: 'Add one class manually, e.g. S.2 East'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSavingClass ? null : _addClassManual,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generate Classes', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('This school uses streams'),
                      subtitle: const Text('e.g. S.2 East / S.2 West, instead of just S.2'),
                      value: _useStreams,
                      onChanged: (v) => setState(() => _useStreams = v),
                    ),
                    if (_useStreams) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _streamInputController,
                              decoration: const InputDecoration(hintText: 'Stream name, e.g. East'),
                              onSubmitted: (_) => _addStreamName(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(onPressed: _addStreamName, icon: const Icon(Icons.add)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _streamNames
                            .map((s) => Chip(
                          label: Text(s),
                          onDeleted: () => setState(() => _streamNames.remove(s)),
                        ))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (level != null) ...[
                      Text(
                        'Generate for: ${level == SchoolLevel.primary ? "Primary (P.1–P.7)" : level == SchoolLevel.secondary ? "Secondary (S.1–S.4)" : "Primary & Secondary"}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: (_isGenerating || (_useStreams && _streamNames.isEmpty))
                              ? null
                              : () => _generateClasses(levelOptions),
                          icon: const Icon(Icons.auto_awesome),
                          label: Text(_isGenerating ? 'Generating...' : 'Generate All Classes'),
                        ),
                      ),
                      if (_useStreams && _streamNames.isEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Add at least one stream name first.',
                            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                      ],
                    ] else
                      const Text('Set the school level in School Settings first.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            StreamBuilder<List<SchoolClass>>(
              stream: _classService.watchClasses(widget.currentUser.schoolId),
              builder: (context, snapshot) {
                final classes = snapshot.data ?? [];
                if (classes.isEmpty) return const Text('No classes yet.');
                return Column(
                  children: classes
                      .map((c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.class_),
                    title: Text(c.name),
                    subtitle: c.classTeacherId != null ? const Text('Has a class teacher') : null,
                  ))
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectsColumn() {
    return FutureBuilder<School>(
      future: SchoolService().fetchSchool(widget.currentUser.schoolId),
      builder: (context, schoolSnapshot) {
        final level = schoolSnapshot.data?.level;
        final presets = level == SchoolLevel.primary
            ? UgandaSubjects.allPrimary
            : level == SchoolLevel.secondary
            ? UgandaSubjects.secondary
            : [...UgandaSubjects.allPrimary, ...UgandaSubjects.secondary];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subjectNameController,
                    decoration: const InputDecoration(hintText: 'e.g. Mathematics'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isSavingSubject ? null : _addSubject,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (level != null) ...[
              const SizedBox(height: 8),
              Text('Tap to add:', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: presets
                    .map((name) => ActionChip(
                  label: Text(name),
                  onPressed: () {
                    _subjectNameController.text = name;
                    _addSubject();
                  },
                ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            StreamBuilder<List<Subject>>(
              stream: _classService.watchSubjects(widget.currentUser.schoolId),
              builder: (context, snapshot) {
                final subjects = snapshot.data ?? [];
                if (subjects.isEmpty) return const Text('No subjects yet.');
                return Column(
                  children: subjects
                      .map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.book),
                    title: Text(s.name),
                  ))
                      .toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }
}