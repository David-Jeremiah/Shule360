import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../permissions/role.dart';
import '../services/class_service.dart';
import '../widgets/add_student_form.dart';
import '../widgets/school_shell.dart';

class RegisterStudentScreen extends StatefulWidget {
  final AppUser currentUser;

  const RegisterStudentScreen({super.key, required this.currentUser});

  @override
  State<RegisterStudentScreen> createState() => _RegisterStudentScreenState();
}

class _RegisterStudentScreenState extends State<RegisterStudentScreen> {
  // Created ONCE in initState — never call the Firestore fetch directly
  // inside build(), since every rebuild would otherwise re-trigger it.
  Future<SchoolClass?>? _classFuture;

  bool get _isLockedToOwnClass =>
      widget.currentUser.role == UserRole.classTeacher &&
          widget.currentUser.ownedClassId != null;

  @override
  void initState() {
    super.initState();
    if (_isLockedToOwnClass) {
      _classFuture = ClassService().fetchClass(
        widget.currentUser.schoolId,
        widget.currentUser.ownedClassId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SchoolScaffold(
      currentUser: widget.currentUser,
      pageTitle: 'Register Student',
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: _isLockedToOwnClass
            ? FutureBuilder<SchoolClass?>(
          future: _classFuture,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            return ClassRosterPanel(currentUser: widget.currentUser, lockedClass: snap.data);
          },
        )
            : ClassRosterPanel(currentUser: widget.currentUser),
      ),
    );
  }
}