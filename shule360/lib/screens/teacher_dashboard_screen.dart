import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';
import 'select_class_subject_screen.dart';
import 'enter_marks_screen.dart';
import 'syllabus_tracker_screen.dart';
import 'teacher_attendance_screen.dart';
import 'register_student_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  final AppUser user;
  final String term;

  const TeacherDashboardScreen({super.key, required this.user, required this.term});

  @override
  Widget build(BuildContext context) {
    final canRegisterStudents = Permissions.can(user.role, Capability.manageOwnClassStudents);
    final hasAssignedClass = user.ownedClassId != null;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user.fullName}', style: Theme.of(context).textTheme.headlineSmall),
            if (user.role == UserRole.classTeacher && !hasAssignedClass) ...[
              const SizedBox(height: 8),
              Text(
                'You haven\'t been assigned a class yet — ask your Head Teacher, DOS, or School Admin to assign one before you can register students.',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Check In to Class'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(currentUser: user)),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.edit_note),
              label: const Text('Enter Marks'),
              onPressed: user.subjectIds.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectClassSubjectScreen(
                    currentUser: user,
                    title: 'Select Class & Subject',
                    allowedSubjectIds: user.subjectIds,
                    onSelected: (classId, subjectId) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EnterMarksScreen(
                            currentUser: user,
                            classId: classId,
                            subjectId: subjectId,
                            term: term,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.checklist),
              label: const Text('Syllabus Coverage'),
              onPressed: user.subjectIds.isEmpty
                  ? null
                  : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectClassSubjectScreen(
                    currentUser: user,
                    title: 'Select Class & Subject',
                    allowedSubjectIds: user.subjectIds,
                    onSelected: (classId, subjectId) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SyllabusTrackerScreen(
                            currentUser: user,
                            classId: classId,
                            subjectId: subjectId,
                            term: term,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            if (canRegisterStudents) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('Register Student'),
                onPressed: (user.role == UserRole.classTeacher && !hasAssignedClass)
                    ? null
                    : () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RegisterStudentScreen(currentUser: user)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}