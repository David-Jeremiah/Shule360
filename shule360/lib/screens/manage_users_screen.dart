import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../permissions/role.dart';
import '../services/user_admin_service.dart';

class ManageUsersScreen extends StatefulWidget {
  final AppUser currentUser;

  const ManageUsersScreen({super.key, required this.currentUser});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _service = UserAdminService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.teacher;
  bool _isCreating = false;

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || email.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields — password needs 6+ characters')),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      await _service.createStaffAccount(
        email: email,
        password: password,
        fullName: name,
        schoolId: widget.currentUser.schoolId,
        role: _selectedRole,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created for $name')),
        );
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not create account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'HM@stamayass.shule360',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary password'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                    .toList(),
                onChanged: (r) => setState(() => _selectedRole = r ?? UserRole.teacher),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isCreating ? null : _createAccount,
                child: Text(_isCreating ? 'Creating...' : 'Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}