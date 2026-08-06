import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/syllabus_coverage_mark.dart';
import '../models/syllabus_target.dart';
import '../models/syllabus_topic.dart';

class SyllabusService {
  final _db = FirebaseFirestore.instance;
  String _topicsPath(String schoolId) => 'schools/$schoolId/syllabusTopics';
  String _coveragePath(String schoolId) => 'schools/$schoolId/syllabusCoverage';
  String _targetsPath(String schoolId) => 'schools/$schoolId/syllabusTargets';

  /// Adds a topic ONCE for the whole level — every stream at that level
  /// shares it. Skips if a topic with the same title already exists for
  /// this subject/level/term, so re-adding doesn't duplicate.
  Future<void> addTopic(SyllabusTopic topic) async {
    final existing = await _db
        .collection(_topicsPath(topic.schoolId))
        .where('subjectId', isEqualTo: topic.subjectId)
        .where('levelLabel', isEqualTo: topic.levelLabel)
        .where('term', isEqualTo: topic.term)
        .where('title', isEqualTo: topic.title)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _db.collection(_topicsPath(topic.schoolId)).doc(topic.id).set(topic.toMap());
  }

  Stream<List<SyllabusTopic>> watchTopics({
    required String schoolId,
    required String subjectId,
    required String levelLabel,
    required String term,
  }) {
    return _db
        .collection(_topicsPath(schoolId))
        .where('subjectId', isEqualTo: subjectId)
        .where('levelLabel', isEqualTo: levelLabel)
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SyllabusTopic.fromMap(d.id, d.data())).toList());
  }

  /// One coverage mark per (topic, stream) pair — created lazily the first
  /// time a teacher touches it.
  Future<void> markCovered({
    required String schoolId,
    required SyllabusTopic topic,
    required String classId,
    required String teacherId,
  }) async {
    final id = '${topic.id}_$classId';
    await _db.collection(_coveragePath(schoolId)).doc(id).set(
      SyllabusCoverageMark(
        id: id,
        schoolId: schoolId,
        topicId: topic.id,
        classId: classId,
        subjectId: topic.subjectId,
        term: topic.term,
        isCovered: true,
        coveredAt: DateTime.now(),
        coveredByTeacherId: teacherId,
      ).toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> approveCoverage({
    required String schoolId,
    required String coverageMarkId,
    required String hodUserId,
  }) async {
    await _db.collection(_coveragePath(schoolId)).doc(coverageMarkId).set({
      'hodApproved': true,
      'hodApprovedByUserId': hodUserId,
      'hodApprovedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  /// All coverage marks for one specific stream — used by the teacher's
  /// tracker screen, joined against the shared topic list in the UI.
  Stream<List<SyllabusCoverageMark>> watchCoverageForClass({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String term,
  }) {
    return _db
        .collection(_coveragePath(schoolId))
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => SyllabusCoverageMark.fromMap(d.id, d.data())).toList());
  }

  Stream<List<SyllabusCoverageMark>> watchPendingApproval({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String term,
  }) {
    return watchCoverageForClass(schoolId: schoolId, classId: classId, subjectId: subjectId, term: term)
        .map((marks) => marks.where((m) => m.isCovered && !m.hodApproved).toList());
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