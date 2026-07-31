import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../services/class_service.dart';

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
  bool _isSavingClass = false;
  bool _isSavingSubject = false;

  Future<void> _addClass() async {
    final name = _classNameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _isSavingClass = true);
    try {
      final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
      await _classService.createClass(SchoolClass(
        id: id,
        schoolId: widget.currentUser.schoolId,
        name: name,
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
      final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
      await _classService.createSubject(Subject(
        id: id,
        schoolId: widget.currentUser.schoolId,
        name: name,
        levelScope: EducationLevelScope.both,
      ));
      _subjectNameController.clear();
    } finally {
      if (mounted) setState(() => _isSavingSubject = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Classes & Subjects')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildClassesColumn()),
            const SizedBox(width: 32),
            Expanded(child: _buildSubjectsColumn()),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesColumn() {
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
                decoration: const InputDecoration(hintText: 'e.g. S.2 East, P.5'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSavingClass ? null : _addClass,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubjectsColumn() {
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
  }
}