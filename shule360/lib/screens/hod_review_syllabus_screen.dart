import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/syllabus_coverage_mark.dart';
import '../models/syllabus_topic.dart';
import '../services/syllabus_service.dart';
import '../services/class_service.dart';
import '../widgets/sign_out_button.dart';

class HodReviewSyllabusScreen extends StatefulWidget {
  final AppUser currentUser;
  final String classId;
  final String subjectId;
  final String term;

  const HodReviewSyllabusScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.subjectId,
    required this.term,
  });

  @override
  State<HodReviewSyllabusScreen> createState() => _HodReviewSyllabusScreenState();
}

class _HodReviewSyllabusScreenState extends State<HodReviewSyllabusScreen> {
  final _syllabusService = SyllabusService();
  final _classService = ClassService();
  String? _levelLabel;

  @override
  void initState() {
    super.initState();
    _classService.fetchClass(widget.currentUser.schoolId, widget.classId).then((c) {
      if (mounted) setState(() => _levelLabel = c?.levelLabel);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_levelLabel == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review Syllabus Submissions'), actions: const [SignOutButton()]),
      body: StreamBuilder<List<SyllabusCoverageMark>>(
        stream: _syllabusService.watchPendingApproval(
          schoolId: widget.currentUser.schoolId,
          classId: widget.classId,
          subjectId: widget.subjectId,
          term: widget.term,
        ),
        builder: (context, markSnapshot) {
          final marks = markSnapshot.data ?? [];
          if (marks.isEmpty) {
            return const Center(child: Text('Nothing pending approval right now.'));
          }
          return StreamBuilder<List<SyllabusTopic>>(
            stream: _syllabusService.watchTopics(
              schoolId: widget.currentUser.schoolId,
              subjectId: widget.subjectId,
              levelLabel: _levelLabel!,
              term: widget.term,
            ),
            builder: (context, topicSnapshot) {
              final titleById = {for (final t in topicSnapshot.data ?? <SyllabusTopic>[]) t.id: t.title};
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: marks.length,
                itemBuilder: (context, index) {
                  final mark = marks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(titleById[mark.topicId] ?? 'Untitled topic'),
                      subtitle: Text('Covered ${mark.coveredAt?.toLocal().toString().split(' ')[0] ?? ''}'),
                      trailing: FilledButton(
                        onPressed: () => _syllabusService.approveCoverage(
                          schoolId: widget.currentUser.schoolId,
                          coverageMarkId: mark.id,
                          hodUserId: widget.currentUser.id,
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}