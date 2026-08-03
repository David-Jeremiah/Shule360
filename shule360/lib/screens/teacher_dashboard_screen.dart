import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../permissions/role.dart';
import 'select_class_subject_screen.dart';
import 'enter_marks_screen.dart';
import 'syllabus_tracker_screen.dart';
import 'teacher_attendance_screen.dart';
import 'select_my_class_screen.dart';

class TeacherDashboardScreen extends StatelessWidget {
  final AppUser user;
  final String term;

  const TeacherDashboardScreen({super.key, required this.user, required this.term});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${user.fullName}', style: Theme.of(context).textTheme.headlineSmall),
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectClassSubjectScreen(
                    currentUser: user,
                    title: 'Select Class & Subject',
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
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SelectClassSubjectScreen(
                    currentUser: user,
                    title: 'Select Class & Subject',
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
            if (user.role == UserRole.classTeacher) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.class_),
                label: const Text('Select My Class'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SelectMyClassScreen(currentUser: user)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}