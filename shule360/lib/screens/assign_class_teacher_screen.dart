import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../permissions/role.dart';
import '../services/class_service.dart';
import '../services/user_admin_service.dart';
import '../widgets/sign_out_button.dart';

class AssignClassTeacherScreen extends StatelessWidget {
  final AppUser currentUser;

  const AssignClassTeacherScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final classService = ClassService();
    final userService = UserAdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('Assign Class Teacher'), actions: const [SignOutButton()]),
      body: StreamBuilder<List<SchoolClass>>(
        stream: classService.watchClasses(currentUser.schoolId),
        builder: (context, classSnapshot) {
          final classes = classSnapshot.data ?? [];
          if (classes.isEmpty) return const Center(child: Text('No classes yet.'));

          return StreamBuilder<List<AppUser>>(
            stream: userService.watchSchoolUsers(currentUser.schoolId),
            builder: (context, userSnapshot) {
              final classTeachers = (userSnapshot.data ?? [])
                  .where((u) => u.role == UserRole.classTeacher)
                  .toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  final c = classes[index];
                  final assignedTeacher = classTeachers
                      .where((t) => t.id == c.classTeacherId)
                      .cast<AppUser?>()
                      .firstOrNull;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        assignedTeacher != null ? Icons.check_circle : Icons.help_outline,
                        color: assignedTeacher != null ? Colors.green : Colors.orange,
                      ),
                      title: Text(c.name),
                      subtitle: Text(assignedTeacher != null
                          ? 'Class teacher: ${assignedTeacher.fullName}'
                          : 'No class teacher assigned'),
                      trailing: classTeachers.isEmpty
                          ? const Text('No Class Teacher accounts yet')
                          : DropdownButton<String>(
                        hint: const Text('Assign'),
                        value: assignedTeacher?.id,
                        items: classTeachers
                            .map((t) => DropdownMenuItem(value: t.id, child: Text(t.fullName)))
                            .toList(),
                        onChanged: (teacherId) {
                          if (teacherId == null) return;
                          classService.assignClassTeacher(
                            schoolId: currentUser.schoolId,
                            classId: c.id,
                            teacherUserId: teacherId,
                          );
                        },
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