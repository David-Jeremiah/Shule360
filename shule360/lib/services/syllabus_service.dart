import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/syllabus_target.dart';
import '../models/syllabus_topic.dart';

class SyllabusService {
  final _db = FirebaseFirestore.instance;
  String _topicsPath(String schoolId) => 'schools/$schoolId/syllabusCoverage';
  String _targetsPath(String schoolId) => 'schools/$schoolId/syllabusTargets';

  Future<void> addTopic(SyllabusTopic topic) async {
    await _db.collection(_topicsPath(topic.schoolId)).doc(topic.id).set(topic.toMap());
  }

  /// Teacher marks a topic as covered — this is a proposal awaiting HOD
  /// approval, not the final signal.
  Future<void> markCovered(SyllabusTopic topic, String teacherId) async {
    await _db.collection(_topicsPath(topic.schoolId)).doc(topic.id).set({
      'isCovered': true,
      'coveredAt': DateTime.now().toIso8601String(),
      'coveredByTeacherId': teacherId,
    }, SetOptions(merge: true));
  }

  /// HOD approves a topic a teacher marked covered.
  Future<void> approveTopic({
    required String schoolId,
    required String topicId,
    required String hodUserId,
  }) async {
    await _db.collection(_topicsPath(schoolId)).doc(topicId).set({
      'hodApproved': true,
      'hodApprovedByUserId': hodUserId,
      'hodApprovedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Stream<List<SyllabusTopic>> watchTopics({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String term,
  }) {
    return _db
        .collection(_topicsPath(schoolId))
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SyllabusTopic.fromMap(d.id, d.data())).toList());
  }

  /// Topics covered by a teacher but not yet approved — for the HOD review
  /// queue, scoped to a subject/class/term.
  Stream<List<SyllabusTopic>> watchPendingApproval({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String term,
  }) {
    return watchTopics(
      schoolId: schoolId,
      classId: classId,
      subjectId: subjectId,
      term: term,
    ).map((topics) => topics.where((t) => t.isCovered && !t.hodApproved).toList());
  }

  Future<void> setTarget(SyllabusTarget target) async {
    await _db.collection(_targetsPath(target.schoolId)).doc(target.id).set(target.toMap());
  }

  Stream<SyllabusTarget?> watchTarget({
    required String schoolId,
    required String subjectId,
    required String classId,
    required String term,
  }) {
    final id = '${subjectId}_${classId}_$term';
    return _db.collection(_targetsPath(schoolId)).doc(id).snapshots().map(
          (doc) => doc.exists ? SyllabusTarget.fromMap(doc.id, doc.data()!) : null,
    );
  }
}