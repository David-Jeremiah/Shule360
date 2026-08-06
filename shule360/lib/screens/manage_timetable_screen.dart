import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';
import '../permissions/role.dart';
import '../services/class_service.dart';
import '../services/timetable_service.dart';
import '../services/user_admin_service.dart';
import '../widgets/sign_out_button.dart';

class ManageTimetableScreen extends StatefulWidget {
  final AppUser currentUser;

  const ManageTimetableScreen({super.key, required this.currentUser});

  @override
  State<ManageTimetableScreen> createState() => _ManageTimetableScreenState();
}

class _ManageTimetableScreenState extends State<ManageTimetableScreen> {
  final _classService = ClassService();
  final _userService = UserAdminService();
  final _timetableService = TimetableService();

  SchoolClass? _selectedClass;
  Subject? _selectedSubject;
  AppUser? _selectedTeacher;
  int _dayOfWeek = 1;
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 8, minute: 40);
  bool _isSaving = false;

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _addSlot() async {
    if (_selectedClass == null || _selectedSubject == null || _selectedTeacher == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select class, subject, and teacher first')),
      );
      return;
    }

    final startMin = _toMinutes(_startTime);
    final endMin = _toMinutes(_endTime);
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    final levelError = _timetableService.validateSlot(
      teacher: _selectedTeacher!,
      subject: _selectedSubject!,
      schoolClass: _selectedClass!,
    );
    if (levelError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(levelError)));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final overlapError = await _timetableService.validateNoOverlap(
        schoolId: widget.currentUser.schoolId,
        classId: _selectedClass!.id,
        teacherId: _selectedTeacher!.id,
        dayOfWeek: _dayOfWeek,
        startMinutes: startMin,
        endMinutes: endMin,
      );
      if (overlapError != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(overlapError)));
        return;
      }

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await _timetableService.createSlot(TimetableSlot(
        id: id,
        schoolId: widget.currentUser.schoolId,
        classId: _selectedClass!.id,
        subjectId: _selectedSubject!.id,
        teacherId: _selectedTeacher!.id,
        dayOfWeek: _dayOfWeek,
        startMinutes: startMin,
        endMinutes: endMin,
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slot added')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Timetable'), actions: const [SignOutButton()]),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildForm()),
            const SizedBox(width: 24),
            Expanded(flex: 3, child: _buildTimetableView()),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Slot', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              StreamBuilder<List<SchoolClass>>(
                stream: _classService.watchClasses(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final classes = snapshot.data ?? [];
                  return DropdownButtonFormField<SchoolClass>(
                    initialValue: classes.contains(_selectedClass) ? _selectedClass : null,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (c) => setState(() => _selectedClass = c),
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<Subject>>(
                stream: _classService.watchSubjects(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final subjects = snapshot.data ?? [];
                  return DropdownButtonFormField<Subject>(
                    initialValue: subjects.contains(_selectedSubject) ? _selectedSubject : null,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                    onChanged: (s) => setState(() => _selectedSubject = s),
                  );
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<AppUser>>(
                stream: _userService.watchSchoolUsers(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final teachers = (snapshot.data ?? [])
                      .where((u) => u.role == UserRole.teacher || u.role == UserRole.classTeacher)
                      .where((u) => _selectedSubject == null || u.subjectIds.contains(_selectedSubject!.id))
                      .toList();
                  return DropdownButtonFormField<AppUser>(
                    initialValue: teachers.contains(_selectedTeacher) ? _selectedTeacher : null,
                    decoration: InputDecoration(
                      labelText: 'Teacher',
                      helperText: _selectedSubject == null
                          ? null
                          : 'Only showing teachers assigned to ${_selectedSubject!.name}',
                    ),
                    items: teachers.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
                    onChanged: (t) => setState(() => _selectedTeacher = t),
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _dayOfWeek,
                decoration: const InputDecoration(labelText: 'Day'),
                items: List.generate(7, (i) => i + 1)
                    .map((d) => DropdownMenuItem(value: d, child: Text(weekdayNames[d])))
                    .toList(),
                onChanged: (d) => setState(() => _dayOfWeek = d ?? 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _startTime);
                        if (picked != null) setState(() => _startTime = picked);
                      },
                      child: Text('Start: ${_startTime.format(context)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(context: context, initialTime: _endTime);
                        if (picked != null) setState(() => _endTime = picked);
                      },
                      child: Text('End: ${_endTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _addSlot,
                  child: Text(_isSaving ? 'Saving...' : 'Add Slot'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimetableView() {
    if (_selectedClass == null) {
      return const Center(child: Text('Select a class to see its timetable.'));
    }
    return StreamBuilder<List<Subject>>(
      stream: _classService.watchSubjects(widget.currentUser.schoolId),
      builder: (context, subjectSnapshot) {
        final subjectNames = {for (final s in subjectSnapshot.data ?? <Subject>[]) s.id: s.name};
        return StreamBuilder<List<AppUser>>(
          stream: _userService.watchSchoolUsers(widget.currentUser.schoolId),
          builder: (context, userSnapshot) {
            final teacherNames = {for (final u in userSnapshot.data ?? <AppUser>[]) u.id: u.fullName};
            return StreamBuilder<List<TimetableSlot>>(
              stream: _timetableService.watchSlotsForClass(widget.currentUser.schoolId, _selectedClass!.id),
              builder: (context, snapshot) {
                final slots = [...(snapshot.data ?? [])]
                  ..sort((a, b) => a.dayOfWeek != b.dayOfWeek
                      ? a.dayOfWeek.compareTo(b.dayOfWeek)
                      : a.startMinutes.compareTo(b.startMinutes));
                if (slots.isEmpty) {
                  return Text('No slots yet for ${_selectedClass!.name}.');
                }
                return ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (context, index) {
                    final slot = slots[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('${weekdayNames[slot.dayOfWeek]} ${slot.startLabel}–${slot.endLabel}'),
                        subtitle: Text(
                          'Subject: ${subjectNames[slot.subjectId] ?? slot.subjectId}  •  '
                              'Teacher: ${teacherNames[slot.teacherId] ?? slot.teacherId}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _timetableService.deleteSlot(widget.currentUser.schoolId, slot.id),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}