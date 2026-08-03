import 'package:flutter/material.dart';
import '../permissions/role.dart';
import '../services/platform_admin_service.dart';
import '../services/user_admin_service.dart';

class PlatformTeamScreen extends StatefulWidget {
  const PlatformTeamScreen({super.key});

  @override
  State<PlatformTeamScreen> createState() => _PlatformTeamScreenState();
}

class _PlatformTeamScreenState extends State<PlatformTeamScreen> {
  final _service = PlatformAdminService();
  final _userService = UserAdminService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCreating = false;

  Future<void> _addTeamMember() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.length < 6) return;

    setState(() => _isCreating = true);
    try {
      await _userService.createStaffAccount(
        email: email,
        password: password,
        fullName: name,
        schoolId: 'platform',
        role: UserRole.platformAdmin,
      );
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add Team Member', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Temporary password'),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isCreating ? null : _addTeamMember,
                      child: Text(_isCreating ? 'Adding...' : 'Add to Platform Team'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Platform Team', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.watchPlatformTeam(),
              builder: (context, snapshot) {
                final team = snapshot.data ?? [];
                if (team.isEmpty) return const Text('No platform team members yet.');
                return Column(
                  children: team
                      .map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.shield)),
                      title: Text(m['fullName'] ?? 'Unknown'),
                      subtitle: const Text('Shule360 Admin'),
                    ),
                  ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}