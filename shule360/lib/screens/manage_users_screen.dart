import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../permissions/role.dart';
import '../services/class_service.dart';
import '../services/user_admin_service.dart';
import '../widgets/add_student_form.dart';
import '../widgets/school_shell.dart';
import 'edit_user_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  final AppUser currentUser;
  final String schoolSlug;

  const ManageUsersScreen({super.key, required this.currentUser, required this.schoolSlug});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

enum _Panel { staff, students }

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  _Panel _panel = _Panel.staff;

  @override
  Widget build(BuildContext context) {
    return SchoolScaffold(
      currentUser: widget.currentUser,
      pageTitle: 'Manage Users',
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<_Panel>(
              segments: const [
                ButtonSegment(value: _Panel.staff, label: Text('Staff'), icon: Icon(Icons.badge)),
                ButtonSegment(value: _Panel.students, label: Text('Students'), icon: Icon(Icons.groups)),
              ],
              selected: {_panel},
              onSelectionChanged: (s) => setState(() => _panel = s.first),
            ),
            const SizedBox(height: 20),
            if (_panel == _Panel.staff)
              _StaffPanel(currentUser: widget.currentUser, schoolSlug: widget.schoolSlug)
            else
              ClassRosterPanel(currentUser: widget.currentUser),
          ],
        ),
      ),
    );
  }
}

/// Existing staff first, "Add Staff" second — an expandable form rather
/// than a separate screen, so adding someone doesn't lose your place in
/// the list.
class _StaffPanel extends StatefulWidget {
  final AppUser currentUser;
  final String schoolSlug;

  const _StaffPanel({required this.currentUser, required this.schoolSlug});

  @override
  State<_StaffPanel> createState() => _StaffPanelState();
}

class _StaffPanelState extends State<_StaffPanel> {
  final _service = UserAdminService();
  bool _showAddForm = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<List<AppUser>>(
          stream: _service.watchUsers(widget.currentUser.schoolId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const Text(
                'No staff accounts yet — use "Add Staff" below to create the first one.',
                style: TextStyle(fontStyle: FontStyle.italic),
              );
            }
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  for (final user in users) ...[
                    Builder(builder: (context) {
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
                              builder: (_) => EditUserScreen(currentUser: widget.currentUser, targetUser: user),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (user != users.last) const Divider(height: 1),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: Icon(_showAddForm ? Icons.close : Icons.person_add),
          label: Text(_showAddForm ? 'Cancel' : 'Add Staff'),
          onPressed: () => setState(() => _showAddForm = !_showAddForm),
        ),
        if (_showAddForm) ...[
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _AddStaffForm(
                currentUser: widget.currentUser,
                schoolSlug: widget.schoolSlug,
                onCreated: () => setState(() => _showAddForm = false),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AddStaffForm extends StatefulWidget {
  final AppUser currentUser;
  final String schoolSlug;
  final VoidCallback onCreated;

  const _AddStaffForm({required this.currentUser, required this.schoolSlug, required this.onCreated});

  @override
  State<_AddStaffForm> createState() => _AddStaffFormState();
}

class _AddStaffFormState extends State<_AddStaffForm> {
  final _service = UserAdminService();
  final _classService = ClassService();
  final _nameController = TextEditingController();
  final _emailPrefixController = TextEditingController();
  final _passwordController = TextEditingController();
  final _departmentController = TextEditingController(); // free-text, HOD only
  UserRole _selectedRole = UserRole.teacher;
  final Set<String> _selectedSubjectIds = {};
  String? _selectedDepartment; // dropdown pick, teacher/classTeacher only
  bool _isCreating = false;
  bool _prefixManuallyEdited = false;

  String get _domain => '${widget.schoolSlug}.shule360';

  bool get _needsSubjects => _selectedRole == UserRole.teacher || _selectedRole == UserRole.classTeacher;

  bool get _isDepartmentHead => _selectedRole == UserRole.hod;

  bool get _canJoinDepartment => _selectedRole == UserRole.teacher || _selectedRole == UserRole.classTeacher;

  @override
  void dispose() {
    _nameController.dispose();
    _emailPrefixController.dispose();
    _passwordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  String _slugify(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  void _onNameChanged(String value) {
    if (!_prefixManuallyEdited) {
      _emailPrefixController.text = _slugify(value);
    }
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final prefix = _emailPrefixController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty || prefix.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields — password needs 6+ characters')),
      );
      return;
    }

    final email = '$prefix@$_domain';
    final departmentName = _isDepartmentHead
        ? _departmentController.text.trim()
        : (_canJoinDepartment ? _selectedDepartment : null);

    setState(() => _isCreating = true);
    try {
      await _service.createStaffAccount(
        email: email,
        password: password,
        fullName: name,
        schoolId: widget.currentUser.schoolId,
        role: _selectedRole,
        departmentName: departmentName,
        subjectIds: _needsSubjects ? _selectedSubjectIds.toList() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Account created: $email')),
        );
        widget.onCreated();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          onChanged: _onNameChanged,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _emailPrefixController,
          onChanged: (_) => _prefixManuallyEdited = true,
          decoration: InputDecoration(
            labelText: 'Email prefix (auto-filled from name, editable)',
            suffixText: '@$_domain',
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
          items: UserRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
          onChanged: (r) => setState(() {
            _selectedRole = r ?? UserRole.teacher;
            _selectedDepartment = null;
          }),
        ),
        if (_isDepartmentHead) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _departmentController,
            decoration: const InputDecoration(
              labelText: 'Department this person will head',
              hintText: 'e.g. Sports, Science, Chemistry, Physics',
            ),
          ),
        ],
        if (_canJoinDepartment) ...[
          const SizedBox(height: 12),
          StreamBuilder<List<String>>(
            stream: _service.watchDepartmentNames(widget.currentUser.schoolId),
            builder: (context, snapshot) {
              final departments = snapshot.data ?? [];
              if (departments.isEmpty) {
                return const Text(
                  'No departments yet — create an HOD account first to define one.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                );
              }
              return DropdownButtonFormField<String>(
                initialValue: _selectedDepartment,
                decoration: const InputDecoration(labelText: 'Department (optional)'),
                items: departments.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setState(() => _selectedDepartment = v),
              );
            },
          ),
        ],
        if (_needsSubjects) ...[
          const SizedBox(height: 16),
          Text('Subjects taught', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          StreamBuilder<List<Subject>>(
            stream: _classService.watchSubjects(widget.currentUser.schoolId),
            builder: (context, snapshot) {
              final subjects = snapshot.data ?? [];
              if (subjects.isEmpty) {
                return const Text('No subjects created yet — add some under Manage Classes & Subjects first.');
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.map((s) {
                  final selected = _selectedSubjectIds.contains(s.id);
                  return FilterChip(
                    label: Text(s.name),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedSubjectIds.add(s.id);
                      } else {
                        _selectedSubjectIds.remove(s.id);
                      }
                    }),
                  );
                }).toList(),
              );
            },
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isCreating ? null : _createAccount,
            child: Text(_isCreating ? 'Creating...' : 'Create Account'),
          ),
        ),
      ],
    );
  }
}