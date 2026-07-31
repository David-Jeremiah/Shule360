import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/syllabus_topic.dart';

class SyllabusService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/syllabusCoverage';

  Future<void> addTopic(SyllabusTopic topic) async {
    await _db.collection(_path(topic.schoolId)).doc(topic.id).set(topic.toMap());
  }

  Future<void> markCovered(SyllabusTopic topic) async {
    await _db.collection(_path(topic.schoolId)).doc(topic.id).set(
      topic.toMap()..['isCovered'] = true..['coveredAt'] = DateTime.now().toIso8601String(),
      SetOptions(merge: true),
    );
  }

  Stream<List<SyllabusTopic>> watchTopics({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String term,
  }) {
    return _db
        .collection(_path(schoolId))
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SyllabusTopic.fromMap(d.id, d.data())).toList());
  }
}