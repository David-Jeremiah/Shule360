import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/subject.dart';
import '../services/class_service.dart';
import '../services/user_admin_service.dart';

class HodMyTeachersScreen extends StatelessWidget {
  final AppUser currentUser; // must be UserRole.hod

  const HodMyTeachersScreen({super.key, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    final department = currentUser.departmentName;
    final service = UserAdminService();

    if (department == null || department.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Department')),
        body: const Center(child: Text('No department set on your account.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('$department Department')),
      body: StreamBuilder<List<AppUser>>(
        stream: service.watchDepartmentTeachers(
          schoolId: currentUser.schoolId,
          departmentName: department,
        ),
        builder: (context, snapshot) {
          final teachers = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (teachers.isEmpty) {
            return const Center(child: Text('No teachers assigned to your department yet.'));
          }
          return ListView.separated(
            itemCount: teachers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return ListTile(
                title: Text(teacher.fullName),
                subtitle: Text('${teacher.subjectIds.length} subject(s) assigned'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _AssignSubjectsScreen(currentUser: currentUser, teacher: teacher),
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

class _AssignSubjectsScreen extends StatefulWidget {
  final AppUser currentUser;
  final AppUser teacher;

  const _AssignSubjectsScreen({required this.currentUser, required this.teacher});

  @override
  State<_AssignSubjectsScreen> createState() => _AssignSubjectsScreenState();
}

class _AssignSubjectsScreenState extends State<_AssignSubjectsScreen> {
  final _service = UserAdminService();
  final _classService = ClassService();
  late Set<String> _selectedSubjectIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSubjectIds = {...widget.teacher.subjectIds};
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await _service.updateTeacherSubjects(
        userId: widget.teacher.id,
        subjectIds: _selectedSubjectIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subjects updated')),
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
      appBar: AppBar(title: Text('Assign Subjects — ${widget.teacher.fullName}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}