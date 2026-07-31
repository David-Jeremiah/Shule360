import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/teacher_attendance_record.dart';
import '../services/teacher_attendance_service.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final AppUser currentUser;

  const TeacherAttendanceScreen({super.key, required this.currentUser});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  final _service = TeacherAttendanceService();
  final _classIdController = TextEditingController();
  final _subjectIdController = TextEditingController();
  bool _isCheckingIn = false;

  Future<void> _checkIn() async {
    final classId = _classIdController.text.trim();
    final subjectId = _subjectIdController.text.trim();
    if (classId.isEmpty || subjectId.isEmpty) return;

    setState(() => _isCheckingIn = true);
    try {
      final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
      final now = DateTime.now();
      await _service.checkIn(TeacherAttendanceRecord(
        id: id,
        schoolId: widget.currentUser.schoolId,
        teacherId: widget.currentUser.id,
        classId: classId,
        subjectId: subjectId,
        timetableSlotId: 'manual-$id', // TODO: replace once real timetable slots exist
        scheduledStart: now,
        scheduledEnd: now.add(const Duration(minutes: 40)),
        actualCheckIn: now,
        status: AttendanceStatus.onTime, // TODO: compute vs. real timetable once it exists
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked in')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Check-In')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _classIdController,
                decoration: const InputDecoration(labelText: 'Class (e.g. S.2 East)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _subjectIdController,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isCheckingIn ? null : _checkIn,
                icon: const Icon(Icons.login),
                label: const Text('Check In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}