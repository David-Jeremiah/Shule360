import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/syllabus_target.dart';
import '../services/syllabus_service.dart';
import '../widgets/sign_out_button.dart';

class HodSetTargetScreen extends StatefulWidget {
  final AppUser currentUser;
  final String classId;
  final String subjectId;
  final String term;

  const HodSetTargetScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.subjectId,
    required this.term,
  });

  @override
  State<HodSetTargetScreen> createState() => _HodSetTargetScreenState();
}

class _HodSetTargetScreenState extends State<HodSetTargetScreen> {
  final _service = SyllabusService();
  final _weeksController = TextEditingController(text: '10');
  final _passMarkController = TextEditingController(text: '40');
  bool _isSaving = false;

  Future<void> _save() async {
    final weeks = int.tryParse(_weeksController.text.trim());
    final passMark = double.tryParse(_passMarkController.text.trim());
    if (weeks == null || passMark == null) return;

    setState(() => _isSaving = true);
    try {
      final id = '${widget.subjectId}_${widget.classId}_${widget.term}';
      await _service.setTarget(SyllabusTarget(
        id: id,
        schoolId: widget.currentUser.schoolId,
        subjectId: widget.subjectId,
        classId: widget.classId,
        term: widget.term,
        targetWeeks: weeks,
        passMarkTarget: passMark,
        setByUserId: widget.currentUser.id,
        setAt: DateTime.now(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target saved')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Syllabus Target'), actions: const [SignOutButton()]),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _weeksController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target weeks to cover syllabus'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passMarkController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Pass mark target (%)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Target'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}