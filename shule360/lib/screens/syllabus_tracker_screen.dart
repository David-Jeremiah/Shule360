import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/syllabus_coverage_mark.dart';
import '../models/syllabus_target.dart';
import '../models/syllabus_topic.dart';
import '../services/class_service.dart';
import '../services/syllabus_service.dart';
import '../widgets/sign_out_button.dart';

class SyllabusTrackerScreen extends StatefulWidget {
  final AppUser currentUser;
  final String classId;
  final String subjectId;
  final String term;

  const SyllabusTrackerScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.subjectId,
    required this.term,
  });

  @override
  State<SyllabusTrackerScreen> createState() => _SyllabusTrackerScreenState();
}

class _SyllabusTrackerScreenState extends State<SyllabusTrackerScreen> {
  final _service = SyllabusService();
  final _classService = ClassService();
  final _titleController = TextEditingController();
  SchoolClass? _schoolClass;

  @override
  void initState() {
    super.initState();
    _classService.fetchClass(widget.currentUser.schoolId, widget.classId).then((c) {
      if (mounted) setState(() => _schoolClass = c);
    });
  }

  Future<void> _addTopic() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _schoolClass == null) return;
    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.addTopic(SyllabusTopic(
      id: id,
      schoolId: widget.currentUser.schoolId,
      subjectId: widget.subjectId,
      levelLabel: _schoolClass!.levelLabel,
      term: widget.term,
      title: title,
    ));
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_schoolClass == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final levelLabel = _schoolClass!.levelLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text('Syllabus — ${_schoolClass!.name}'),
        actions: const [SignOutButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<SyllabusTarget?>(
              stream: _service.watchTarget(
                schoolId: widget.currentUser.schoolId,
                subjectId: widget.subjectId,
                classId: widget.classId,
                term: widget.term,
              ),
              builder: (context, snapshot) {
                final target = snapshot.data;
                if (target == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('No target set yet by your HOD.'),
                    ),
                  );
                }
                return Card(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.flag),
                        const SizedBox(width: 10),
                        Text('Target: cover in ${target.targetWeeks} weeks • Pass mark: ${target.passMarkTarget}%'),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text('Topics are shared across all $levelLabel streams — coverage below is tracked for ${_schoolClass!.name} only.',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(hintText: 'Add topic for $levelLabel, e.g. Photosynthesis'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addTopic, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SyllabusTopic>>(
                stream: _service.watchTopics(
                  schoolId: widget.currentUser.schoolId,
                  subjectId: widget.subjectId,
                  levelLabel: levelLabel,
                  term: widget.term,
                ),
                builder: (context, topicSnapshot) {
                  final topics = topicSnapshot.data ?? [];
                  if (topics.isEmpty) return const Text('No topics added yet for this level.');

                  return StreamBuilder<List<SyllabusCoverageMark>>(
                    stream: _service.watchCoverageForClass(
                      schoolId: widget.currentUser.schoolId,
                      classId: widget.classId,
                      subjectId: widget.subjectId,
                      term: widget.term,
                    ),
                    builder: (context, coverageSnapshot) {
                      final marksByTopic = {
                        for (final m in coverageSnapshot.data ?? <SyllabusCoverageMark>[]) m.topicId: m
                      };
                      final approvedCount = topics.where((t) => marksByTopic[t.id]?.hodApproved == true).length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(value: topics.isEmpty ? 0 : approvedCount / topics.length),
                          const SizedBox(height: 4),
                          Text('$approvedCount / ${topics.length} topics approved for ${_schoolClass!.name}'),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.builder(
                              itemCount: topics.length,
                              itemBuilder: (context, index) {
                                final topic = topics[index];
                                final mark = marksByTopic[topic.id];
                                final isCovered = mark?.isCovered ?? false;
                                final isApproved = mark?.hodApproved ?? false;
                                return ListTile(
                                  title: Text(topic.title),
                                  leading: Icon(
                                    isApproved
                                        ? Icons.verified
                                        : (isCovered ? Icons.hourglass_top : Icons.circle_outlined),
                                    color: isApproved ? Colors.green : (isCovered ? Colors.orange : null),
                                  ),
                                  subtitle: Text(
                                    isApproved
                                        ? 'Approved by HOD'
                                        : (isCovered ? 'Marked covered — awaiting approval' : 'Not yet covered'),
                                  ),
                                  trailing: isCovered
                                      ? null
                                      : TextButton(
                                    onPressed: () => _service.markCovered(
                                      schoolId: widget.currentUser.schoolId,
                                      topic: topic,
                                      classId: widget.classId,
                                      teacherId: widget.currentUser.id,
                                    ),
                                    child: const Text('Mark Covered'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}