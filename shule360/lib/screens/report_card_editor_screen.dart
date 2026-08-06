import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/report_card_mark.dart';
import '../models/school.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../services/comment_suggestion_service.dart';
import '../services/report_card_pdf_service.dart';
import '../services/report_card_service.dart';
import '../services/school_service.dart';
import '../services/subject_service.dart';
import '../widgets/school_shell.dart';

/// The assessment-component columns printed on the report, in order.
/// Change this list (and nothing else) to match a different school's
/// column layout — e.g. drop down to just ['CA', 'EOT'] for a school
/// that only runs continuous assessment + end of term.
const kReportCardComponents = ['BOT', 'MT', 'EOT', 'HW', 'T1', 'MOT'];

class ReportCardEditorScreen extends StatefulWidget {
  final AppUser currentUser;
  final Student student;
  final String classId;
  final String term;

  const ReportCardEditorScreen({
    super.key,
    required this.currentUser,
    required this.student,
    required this.classId,
    required this.term,
  });

  @override
  State<ReportCardEditorScreen> createState() => _ReportCardEditorScreenState();
}

class _SubjectEntry {
  final String subjectId;
  final String subjectName;
  final Map<String, TextEditingController> componentControllers;
  final TextEditingController commentController;
  final TextEditingController initialsController;

  _SubjectEntry({
    required this.subjectId,
    required this.subjectName,
    required this.componentControllers,
    required this.commentController,
    required this.initialsController,
  });

  double get average {
    final values = componentControllers.values
        .map((c) => double.tryParse(c.text.trim()))
        .whereType<double>()
        .toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  ReportCardSubjectMark toMark() => ReportCardSubjectMark(
    subjectId: subjectId,
    subjectName: subjectName,
    componentScores: {
      for (final e in componentControllers.entries)
        if (double.tryParse(e.value.text.trim()) != null) e.key: double.parse(e.value.text.trim()),
    },
    comment: commentController.text.trim().isEmpty ? null : commentController.text.trim(),
    teacherInitials: initialsController.text.trim().isEmpty ? null : initialsController.text.trim(),
  );

  void dispose() {
    for (final c in componentControllers.values) {
      c.dispose();
    }
    commentController.dispose();
    initialsController.dispose();
  }
}

class _ReportCardEditorScreenState extends State<ReportCardEditorScreen> {
  final _reportCardService = ReportCardService();
  final _subjectService = SubjectService();
  final _schoolService = SchoolService();
  final _pdfService = ReportCardPdfService();
  final _commentSuggestions = CommentSuggestionService();

  List<Subject> _allSubjects = [];
  final List<_SubjectEntry> _entries = [];

  final _classTeacherCommentController = TextEditingController();
  final _conductCommentController = TextEditingController();
  final _headTeacherCommentController = TextEditingController();
  final _feesBalanceController = TextEditingController();
  final _studentPhotoUrlController = TextEditingController();
  final _classPositionController = TextEditingController();
  final _classSizeController = TextEditingController();

  String? _gender;
  DateTime? _termEndDate;
  DateTime? _nextTermStartDate;

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final subjects = await _subjectService.fetchSubjectsForSchool(widget.currentUser.schoolId);
    final existing = await _reportCardService.fetch(
      schoolId: widget.currentUser.schoolId,
      classId: widget.classId,
      studentId: widget.student.id,
      term: widget.term,
    );

    setState(() {
      _allSubjects = subjects;
      if (existing != null) {
        for (final mark in existing.subjectMarks) {
          _entries.add(_entryFrom(mark));
        }
        _gender = existing.gender;
        _studentPhotoUrlController.text = existing.studentPhotoUrl ?? '';
        _classPositionController.text = existing.classPosition?.toString() ?? '';
        _classSizeController.text = existing.classSize?.toString() ?? '';
        _termEndDate = existing.termEndDate;
        _nextTermStartDate = existing.nextTermStartDate;
        _feesBalanceController.text = existing.feesBalance?.toStringAsFixed(0) ?? '';
        _classTeacherCommentController.text = existing.comments.classTeacherComment ?? '';
        _conductCommentController.text = existing.comments.conductComment ?? '';
        _headTeacherCommentController.text = existing.comments.headTeacherComment ?? '';
      }
      _loading = false;
    });
  }

  _SubjectEntry _entryFrom(ReportCardSubjectMark mark) {
    return _SubjectEntry(
      subjectId: mark.subjectId,
      subjectName: mark.subjectName,
      componentControllers: {
        for (final c in kReportCardComponents)
          c: TextEditingController(text: mark.componentScores[c]?.toStringAsFixed(0) ?? ''),
      },
      commentController: TextEditingController(text: mark.comment ?? ''),
      initialsController: TextEditingController(text: mark.teacherInitials ?? ''),
    );
  }

  void _addSubject(Subject subject) {
    setState(() {
      _entries.add(_SubjectEntry(
        subjectId: subject.id,
        subjectName: subject.name,
        componentControllers: {for (final c in kReportCardComponents) c: TextEditingController()},
        commentController: TextEditingController(),
        initialsController: TextEditingController(),
      ));
    });
  }

  void _removeSubject(_SubjectEntry entry) {
    setState(() {
      entry.dispose();
      _entries.remove(entry);
    });
  }

  double get _overallAverage {
    if (_entries.isEmpty) return 0;
    return _entries.map((e) => e.average).reduce((a, b) => a + b) / _entries.length;
  }

  ReportCardRecord _buildRecord() {
    return ReportCardRecord(
      schoolId: widget.currentUser.schoolId,
      classId: widget.classId,
      studentId: widget.student.id,
      term: widget.term,
      subjectMarks: _entries.map((e) => e.toMark()).toList(),
      comments: ReportCardComments(
        classTeacherComment: _classTeacherCommentController.text.trim().isEmpty
            ? null
            : _classTeacherCommentController.text.trim(),
        conductComment:
        _conductCommentController.text.trim().isEmpty ? null : _conductCommentController.text.trim(),
        headTeacherComment: _headTeacherCommentController.text.trim().isEmpty
            ? null
            : _headTeacherCommentController.text.trim(),
      ),
      gender: _gender,
      studentPhotoUrl: _studentPhotoUrlController.text.trim().isEmpty ? null : _studentPhotoUrlController.text.trim(),
      classPosition: int.tryParse(_classPositionController.text.trim()),
      classSize: int.tryParse(_classSizeController.text.trim()),
      termEndDate: _termEndDate,
      nextTermStartDate: _nextTermStartDate,
      feesBalance: double.tryParse(_feesBalanceController.text.trim()),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _reportCardService.save(_buildRecord());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report card saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _print() async {
    final school = await _schoolService.fetchSchool(widget.currentUser.schoolId);
    final record = _buildRecord();
    if (!mounted) return;
    await _pdfService.printReportCard(ReportCardData(
      student: widget.student,
      school: school,
      term: widget.term,
      subjectMarks: record.subjectMarks,
      comments: record.comments,
      gender: record.gender,
      studentPhotoUrl: record.studentPhotoUrl,
      classPosition: record.classPosition,
      classSize: record.classSize,
      termEndDate: record.termEndDate,
      nextTermStartDate: record.nextTermStartDate,
      feesBalance: record.feesBalance,
    ));
  }

  Future<void> _pickDate({required bool isTermEnd}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (isTermEnd) {
        _termEndDate = picked;
      } else {
        _nextTermStartDate = picked;
      }
    });
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    _classTeacherCommentController.dispose();
    _conductCommentController.dispose();
    _headTeacherCommentController.dispose();
    _feesBalanceController.dispose();
    _studentPhotoUrlController.dispose();
    _classPositionController.dispose();
    _classSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SchoolScaffold(
      currentUser: widget.currentUser,
      pageTitle: '${widget.student.fullName} — Report Card',
      breadcrumb: 'Report Cards / ${widget.student.fullName}',
      term: widget.term,
      body: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Admission: ${widget.student.admissionNumber}')),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'M', child: Text('Male')),
                    DropdownMenuItem(value: 'F', child: Text('Female')),
                  ],
                  onChanged: (v) => setState(() => _gender = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Subjects', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._entries.map(_buildSubjectCard),
          const SizedBox(height: 8),
          _buildAddSubjectButton(context),
          const SizedBox(height: 24),
          Text('Position & Fees', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _classPositionController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Class position'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _classSizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Out of (class size)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _feesBalanceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fees balance'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(_termEndDate == null ? 'Term end date' : _fmt(_termEndDate!)),
                  onPressed: () => _pickDate(isTermEnd: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(_nextTermStartDate == null ? 'Next term begins' : _fmt(_nextTermStartDate!)),
                  onPressed: () => _pickDate(isTermEnd: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _studentPhotoUrlController,
            decoration: const InputDecoration(labelText: 'Student photo URL (optional)'),
          ),
          const SizedBox(height: 24),
          Text('Comments', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildOverallComment(
            label: "Class Teacher's Comment",
            controller: _classTeacherCommentController,
            onSuggest: () => setState(() => _classTeacherCommentController.text =
                _commentSuggestions.suggestOverallComment(_overallAverage)),
          ),
          _buildOverallComment(
            label: 'Conduct Comment',
            controller: _conductCommentController,
            onSuggest: () =>
                setState(() => _conductCommentController.text = _commentSuggestions.suggestConductComment()),
          ),
          _buildOverallComment(
            label: "Head Teacher's Comment",
            controller: _headTeacherCommentController,
            onSuggest: () => setState(() => _headTeacherCommentController.text =
                _commentSuggestions.suggestOverallComment(_overallAverage)),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Save'),
                onPressed: _saving ? null : _save,
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Save & Print'),
                onPressed: _saving
                    ? null
                    : () async {
                  await _save();
                  await _print();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAddSubjectButton(BuildContext context) {
    final available = _allSubjects.where((s) => !_entries.any((e) => e.subjectId == s.id)).toList();
    if (available.isEmpty) {
      return const Text('All subjects added.', style: TextStyle(fontStyle: FontStyle.italic));
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.add),
      label: const Text('Add subject'),
      onPressed: () async {
        final picked = await showModalBottomSheet<Subject>(
          context: context,
          builder: (context) => ListView(
            shrinkWrap: true,
            children: available
                .map((s) => ListTile(title: Text(s.name), onTap: () => Navigator.of(context).pop(s)))
                .toList(),
          ),
        );
        if (picked != null) _addSubject(picked);
      },
    );
  }

  Widget _buildSubjectCard(_SubjectEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(entry.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                Text('Avg: ${entry.average.toStringAsFixed(1)}'),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _removeSubject(entry),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kReportCardComponents
                  .map((c) => SizedBox(
                width: 80,
                child: TextField(
                  controller: entry.componentControllers[c],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: c),
                  onChanged: (_) => setState(() {}),
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: entry.commentController,
                    decoration: const InputDecoration(labelText: 'Comment'),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: entry.initialsController,
                    decoration: const InputDecoration(labelText: 'Initials'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Suggest comment',
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  onPressed: () => setState(() => entry.commentController.text =
                      _commentSuggestions.suggestSubjectComment(entry.average, subjectName: entry.subjectName)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallComment({
    required String label,
    required TextEditingController controller,
    required VoidCallback onSuggest,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(labelText: label),
            ),
          ),
          IconButton(
            tooltip: 'Suggest comment',
            icon: const Icon(Icons.auto_awesome),
            onPressed: onSuggest,
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}