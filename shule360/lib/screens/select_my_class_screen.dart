import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../services/class_service.dart';
import '../widgets/sign_out_button.dart';

class SelectMyClassScreen extends StatelessWidget {
  final AppUser currentUser;

  const SelectMyClassScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final service = ClassService();

    return Scaffold(
      appBar: AppBar(title: const Text('Select My Class'), actions: const [SignOutButton()]),
      body: StreamBuilder<List<SchoolClass>>(
        stream: service.watchClasses(currentUser.schoolId),
        builder: (context, snapshot) {
          final classes = snapshot.data ?? [];
          if (classes.isEmpty) {
            return const Center(child: Text('No classes created yet — ask your admin to add one.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classes.length,
            itemBuilder: (context, index) {
              final c = classes[index];
              final isMine = c.classTeacherId == currentUser.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(isMine ? Icons.check_circle : Icons.class_,
                      color: isMine ? Colors.green : null),
                  title: Text(c.name),
                  subtitle: Text(isMine ? 'This is your class' : ''),
                  trailing: isMine
                      ? null
                      : FilledButton(
                    onPressed: () async {
                      await service.assignClassTeacher(
                        schoolId: currentUser.schoolId,
                        classId: c.id,
                        teacherUserId: currentUser.id,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('You are now class teacher for ${c.name}')),
                        );
                      }
                    },
                    child: const Text('Select'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}