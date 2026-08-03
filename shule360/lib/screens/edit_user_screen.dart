import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../permissions/role.dart';
import '../services/class_service.dart';
import '../services/user_admin_service.dart';

class EditUserScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppUser targetUser;

  const EditUserScreen({super.key, required this.currentUser, required this.targetUser});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _service = UserAdminService();
  final _classService = ClassService();
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late UserRole _selectedRole;
  late Set<String> _selectedSubjectIds;
  String? _selectedDepartment;
  bool _isSaving = false;

  bool get _needsSubjects => _selectedRole == UserRole.teacher || _selectedRole == UserRole.classTeacher;
  bool get _isDepartmentHead => _selectedRole == UserRole.hod;
  bool get _canJoinDepartment => _selectedRole == UserRole.teacher || _selectedRole == UserRole.classTeacher;

  @override
  void initState() {
    super.initState();
    final u = widget.targetUser;
    _nameController = TextEditingController(text: u.fullName);
    _departmentController = TextEditingController(text: u.role == UserRole.hod ? (u.departmentName ?? '') : '');
    _selectedDepartment = u.role != UserRole.hod ? u.departmentName : null;
    _selectedRole = u.role;
    _selectedSubjectIds = {...u.subjectIds};
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    final departmentName = _isDepartmentHead
        ? _departmentController.text.trim()
        : (_canJoinDepartment ? _selectedDepartment : null);

    setState(() => _isSaving = true);
    try {
      await _service.updateStaffAccount(
        userId: widget.targetUser.id,
        fullName: name,
        role: _selectedRole,
        departmentName: departmentName,
        subjectIds: _needsSubjects ? _selectedSubjectIds.toList() : [],
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.targetUser.fullName}')),
      body: SingleChildScrollView(
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
              DropdownButtonFormField<UserRole>(
                initialValue: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.displayName)))
                    .toList(),
                onChanged: (r) => setState(() {
                  _selectedRole = r ?? UserRole.teacher;
                  _selectedDepartment = null;
                }),
              ),
              if (_isDepartmentHead) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _departmentController,
                  decoration: const InputDecoration(labelText: 'Department this person heads'),
                ),
              ],
              if (_canJoinDepartment) ...[
                const SizedBox(height: 12),
                StreamBuilder<List<String>>(
                  stream: _service.watchDepartmentNames(widget.currentUser.schoolId),
                  builder: (context, snapshot) {
                    final departments = snapshot.data ?? [];
                    final currentValue = departments.contains(_selectedDepartment) ? _selectedDepartment : null;
                    return DropdownButtonFormField<String>(
                      initialValue: currentValue,
                      decoration: const InputDecoration(labelText: 'Department (optional)'),
                      items: departments
                          .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                          .toList(),
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
                      return const Text('No subjects created yet.');
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}