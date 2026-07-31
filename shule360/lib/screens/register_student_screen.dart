import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/student.dart';
import '../services/student_service.dart';

class RegisterStudentScreen extends StatefulWidget {
  final AppUser currentUser;

  const RegisterStudentScreen({super.key, required this.currentUser});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _classIdController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  EducationLevel _level = EducationLevel.primary;
  bool _isSaving = false;

  final _studentService = StudentService();

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final newDocId = FirebaseFirestore.instance.collection('placeholder').doc().id;
      final student = Student(
        id: newDocId,
        schoolId: widget.currentUser.schoolId,
        fullName: _fullNameController.text.trim(),
        admissionNumber: _admissionNumberController.text.trim(),
        level: _level,
        classId: _classIdController.text.trim(),
        guardianPhoneNumber: _guardianPhoneController.text.trim().isEmpty
            ? null
            : _guardianPhoneController.text.trim(),
        enrolledOn: DateTime.now(),
      );
      await _studentService.registerStudent(student);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.fullName} registered successfully')),
      );
      _formKey.currentState!.reset();
      _fullNameController.clear();
      _admissionNumberController.clear();
      _classIdController.clear();
      _guardianPhoneController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not register student: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Student')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _admissionNumberController,
                  decoration: const InputDecoration(labelText: 'Admission number'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EducationLevel>(
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Education level'),
                  items: EducationLevel.values
                      .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _level = v ?? EducationLevel.primary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _classIdController,
                  decoration: const InputDecoration(
                    labelText: 'Class (e.g. S.2 East, P.5)',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _guardianPhoneController,
                  decoration: const InputDecoration(labelText: 'Guardian phone (optional)'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Register Student'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}