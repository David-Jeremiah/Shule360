import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/syllabus_topic.dart';
import '../services/syllabus_service.dart';

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
  final _titleController = TextEditingController();

  Future<void> _addTopic() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.addTopic(SyllabusTopic(
      id: id,
      schoolId: widget.currentUser.schoolId,
      subjectId: widget.subjectId,
      classId: widget.classId,
      term: widget.term,
      title: title,
    ));
    _titleController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Syllabus Coverage')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Add topic, e.g. Photosynthesis'),
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
                  classId: widget.classId,
                  subjectId: widget.subjectId,
                  term: widget.term,
                ),
                builder: (context, snapshot) {
                  final topics = snapshot.data ?? [];
                  if (topics.isEmpty) return const Text('No topics added yet.');
                  final coveredCount = topics.where((t) => t.isCovered).length;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: topics.isEmpty ? 0 : coveredCount / topics.length),
                      const SizedBox(height: 4),
                      Text('$coveredCount / ${topics.length} topics covered'),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: topics.length,
                          itemBuilder: (context, index) {
                            final topic = topics[index];
                            return CheckboxListTile(
                              title: Text(topic.title),
                              value: topic.isCovered,
                              onChanged: topic.isCovered
                                  ? null
                                  : (_) => _service.markCovered(topic),
                            );
                          },
                        ),
                      ),
                    ],
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