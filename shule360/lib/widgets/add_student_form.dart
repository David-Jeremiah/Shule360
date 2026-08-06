import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../services/class_service.dart';
import '../services/student_service.dart';

/// Reusable "add a student" form: pick level -> stream (both derived from
/// existing SchoolClass docs, since a class doc already IS a level+stream
/// combination — there's no separate "streams" collection), enter name +
/// optional guardian phone, then save. Admission number and roll number
/// are generated server-side on save and are never user-editable, so this
/// form never shows a number until after a successful save (no unreliable
/// "preview" that might not match what actually gets written).
class AddStudentForm extends StatefulWidget {
  final AppUser currentUser;

  /// When set, class/stream selection is skipped and this class is used
  /// directly — for Class Teachers who may only register into their own
  /// class.
  final SchoolClass? lockedClass;

  final void Function(Student student) onRegistered;

  /// Fires whenever the resolved class changes (including once, on first
  /// build, for [lockedClass]) — lets a parent show a roster underneath.
  final ValueChanged<SchoolClass?>? onClassSelected;

  const AddStudentForm({
    super.key,
    required this.currentUser,
    required this.onRegistered,
    this.lockedClass,
    this.onClassSelected,
  });

  @override
  State<AddStudentForm> createState() => _AddStudentFormState();
}

class _AddStudentFormState extends State<AddStudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _classService = ClassService();
  final _studentService = StudentService();

  // Created ONCE in initState and reused for the widget's lifetime —
  // never recreate a Firestore stream inside build(). Recreating it on
  // every setState (e.g. every dropdown change) rapidly opens/closes
  // native Firestore channels, which is what triggers the Windows
  // "sent a message from native to Flutter on a non-platform thread"
  // crash.
  late final Stream<List<SchoolClass>> _classesStream;

  EducationLevel _level = EducationLevel.primary;
  String? _selectedLevelLabel;
  SchoolClass? _selectedClass;
  bool _isSaving = false;
  bool _lockedClassAnnounced = false;

  @override
  void initState() {
    super.initState();
    _classesStream = _classService.watchClasses(widget.currentUser.schoolId);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _guardianPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final targetClass = widget.lockedClass ?? _selectedClass;
    if (targetClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a class and stream before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final student = await _studentService.registerNewStudent(
        schoolId: widget.currentUser.schoolId,
        fullName: _fullNameController.text.trim(),
        level: _level,
        classId: targetClass.id,
        guardianPhoneNumber: _guardianPhoneController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${student.fullName} registered — Admission ${student.admissionNumber}, Roll ${student.rollNumber}',
          ),
        ),
      );
      _formKey.currentState!.reset();
      _fullNameController.clear();
      _guardianPhoneController.clear();
      widget.onRegistered(student);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not register student: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _announceClass(SchoolClass? c) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onClassSelected?.call(c);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lockedClass != null && !_lockedClassAnnounced) {
      _lockedClassAnnounced = true;
      _announceClass(widget.lockedClass);
    }

    return StreamBuilder<List<SchoolClass>>(
      stream: _classesStream,
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];

        final levelLabels = <String>[];
        for (final c in classes) {
          if (!levelLabels.contains(c.levelLabel)) levelLabels.add(c.levelLabel);
        }

        final streamsForLevel = _selectedLevelLabel == null
            ? <SchoolClass>[]
            : classes.where((c) => c.levelLabel == _selectedLevelLabel).toList();

        // A level with exactly one class and no stream name means there's
        // nothing further to pick — auto-resolve it after this frame
        // (mutating state during build() directly is unsafe).
        if (widget.lockedClass == null &&
            streamsForLevel.length == 1 &&
            streamsForLevel.first.streamName == null &&
            _selectedClass?.id != streamsForLevel.first.id) {
          final autoClass = streamsForLevel.first;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedClass = autoClass);
            _announceClass(autoClass);
          });
        }

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EducationLevel>(
                initialValue: _level,
                decoration: const InputDecoration(labelText: 'Education level'),
                items: EducationLevel.values
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                    .toList(),
                onChanged: (v) => setState(() => _level = v ?? EducationLevel.primary),
              ),
              const SizedBox(height: 16),

              if (widget.lockedClass != null)
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Class'),
                  child: Text(widget.lockedClass!.name),
                )
              else if (classes.isEmpty)
                const Text(
                  'No classes exist yet — create one under Manage Classes & Subjects first.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                )
              else ...[
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLevelLabel,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: levelLabels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setState(() {
                      _selectedLevelLabel = v;
                      _selectedClass = null;
                    }),
                    validator: (v) => v == null ? 'Select a class' : null,
                  ),
                  if (_selectedLevelLabel != null &&
                      !(streamsForLevel.length == 1 && streamsForLevel.first.streamName == null)) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<SchoolClass>(
                      initialValue: streamsForLevel.contains(_selectedClass) ? _selectedClass : null,
                      decoration: const InputDecoration(labelText: 'Stream'),
                      items: streamsForLevel
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.streamName ?? c.name)))
                          .toList(),
                      onChanged: (c) {
                        setState(() => _selectedClass = c);
                        _announceClass(c);
                      },
                      validator: (v) => v == null ? 'Select a stream' : null,
                    ),
                  ],
                ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _guardianPhoneController,
                decoration: const InputDecoration(labelText: 'Guardian phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              const Text(
                'Admission number and roll number are generated automatically when you save.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Register Student'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Combines [AddStudentForm] with a live roster of the currently-selected
/// class underneath it. Used by both RegisterStudentScreen (full page) and
/// the Students tab inside ManageUsersScreen (embedded).
class ClassRosterPanel extends StatefulWidget {
  final AppUser currentUser;
  final SchoolClass? lockedClass;

  const ClassRosterPanel({super.key, required this.currentUser, this.lockedClass});

  @override
  State<ClassRosterPanel> createState() => _ClassRosterPanelState();
}

class _ClassRosterPanelState extends State<ClassRosterPanel> {
  final _studentService = StudentService();
  SchoolClass? _activeClass;

  // Cached separately from _activeClass so we only open a new Firestore
  // listener when the class actually changes — not on every rebuild of
  // this widget (e.g. while the form above is being typed into).
  String? _streamedClassId;
  Stream<List<Student>>? _studentsStream;

  @override
  void initState() {
    super.initState();
    _activeClass = widget.lockedClass;
    _refreshStreamIfNeeded();
  }

  void _refreshStreamIfNeeded() {
    final classId = _activeClass?.id;
    if (classId != null && classId != _streamedClassId) {
      _streamedClassId = classId;
      _studentsStream = _studentService.watchStudentsForClass(
        schoolId: widget.currentUser.schoolId,
        classId: classId,
      );
    }
  }

  void _onClassSelected(SchoolClass? c) {
    if (widget.lockedClass != null) return;
    setState(() {
      _activeClass = c;
      _refreshStreamIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AddStudentForm(
              currentUser: widget.currentUser,
              lockedClass: widget.lockedClass,
              onClassSelected: _onClassSelected,
              onRegistered: (_) {}, // roster below updates live via the stream
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (_activeClass != null && _studentsStream != null) ...[
          Text('Students in ${_activeClass!.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StreamBuilder<List<Student>>(
            stream: _studentsStream,
            builder: (context, snapshot) {
              final students = snapshot.data ?? [];
              if (students.isEmpty) {
                return const Text('No students registered in this class yet.');
              }
              final sorted = [...students]..sort((a, b) => a.rollNumber.compareTo(b.rollNumber));
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: sorted
                      .map((s) => ListTile(
                    leading: CircleAvatar(child: Text(s.rollNumber)),
                    title: Text(s.fullName),
                    subtitle: Text('Admission: ${s.admissionNumber}'),
                  ))
                      .toList(),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}