import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../services/class_service.dart';
import '../services/user_admin_service.dart';
import '../widgets/sign_out_button.dart';

/// Admin-only screen: pick which department owns each subject. A subject
/// must have a department before it shows up scoped on any HOD screen —
/// HODs only ever see subjects tagged with their own departmentName.
class SubjectDepartmentsScreen extends StatelessWidget {
  final AppUser currentUser;

  const SubjectDepartmentsScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final classService = ClassService();
    final userService = UserAdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Subject Departments'), actions: const [SignOutButton()]),
      body: StreamBuilder<List<String>>(
        stream: userService.watchDepartmentNames(currentUser.schoolId),
        builder: (context, deptSnapshot) {
          final departments = deptSnapshot.data ?? [];

          return StreamBuilder<List<Subject>>(
            stream: classService.watchSubjects(currentUser.schoolId),
            builder: (context, subjSnapshot) {
              final subjects = subjSnapshot.data ?? [];
              if (subjects.isEmpty) {
                return const Center(child: Text('No subjects yet — add some under Manage Classes & Subjects first.'));
              }
              if (departments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No departments exist yet — create at least one HOD account '
                        'first (their department name becomes an available department here).',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: subjects.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return ListTile(
                    title: Text(subject.name),
                    subtitle: Text(subject.departmentName == null
                        ? 'No department assigned'
                        : 'Department: ${subject.departmentName}'),
                    trailing: DropdownButton<String?>(
                      value: subject.departmentName,
                      hint: const Text('Assign'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('— None —')),
                        ...departments.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
                      ],
                      onChanged: (value) => classService.updateSubjectDepartment(
                        schoolId: currentUser.schoolId,
                        subjectId: subject.id,
                        departmentName: value,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}