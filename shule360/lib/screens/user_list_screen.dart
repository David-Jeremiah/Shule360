import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/user_admin_service.dart';
import 'edit_user_screen.dart';

class UserListScreen extends StatelessWidget {
  final AppUser currentUser;

  const UserListScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final service = UserAdminService();

    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: StreamBuilder<List<AppUser>>(
        stream: service.watchUsers(currentUser.schoolId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found for this school.'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final subtitleParts = <String>[user.role.displayName];
              if (user.departmentName != null && user.departmentName!.isNotEmpty) {
                subtitleParts.add(user.departmentName!);
              }
              if (user.subjectIds.isNotEmpty) {
                subtitleParts.add('${user.subjectIds.length} subject(s)');
              }
              return ListTile(
                title: Text(user.fullName),
                subtitle: Text(subtitleParts.join(' • ')),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditUserScreen(currentUser: currentUser, targetUser: user),
                    ),
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