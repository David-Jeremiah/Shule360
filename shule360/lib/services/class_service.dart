import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_class.dart';
import '../models/subject.dart';

class ClassService {
  final _db = FirebaseFirestore.instance;

  String _classesPath(String schoolId) => 'schools/$schoolId/classes';
  String _subjectsPath(String schoolId) => 'schools/$schoolId/subjects';

  Future<void> createClass(SchoolClass schoolClass) async {
    await _db.collection(_classesPath(schoolClass.schoolId)).doc(schoolClass.id).set(schoolClass.toMap());
  }

  /// Creates a subject only if one with the same (case-insensitive) name
  /// doesn't already exist for this school — prevents duplicate entries
  /// from repeated taps on quick-add chips.
  Future<void> createSubjectIfNotExists(Subject subject) async {
    final existing = await _db
        .collection(_subjectsPath(subject.schoolId))
        .where('name', isEqualTo: subject.name)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;
    await _db.collection(_subjectsPath(subject.schoolId)).doc(subject.id).set(subject.toMap());
  }

  Future<void> updateSubjectDepartment({
    required String schoolId,
    required String subjectId,
    required String? departmentName,
  }) async {
    await _db.collection(_subjectsPath(schoolId)).doc(subjectId).set(
      {'departmentName': departmentName},
      SetOptions(merge: true),
    );
  }

  Future<SchoolClass?> fetchClass(String schoolId, String classId) async {
    final doc = await _db.collection(_classesPath(schoolId)).doc(classId).get();
    return doc.exists ? SchoolClass.fromMap(doc.id, doc.data()!) : null;
  }

  Stream<List<SchoolClass>> watchClasses(String schoolId) {
    return _db
        .collection(_classesPath(schoolId))
        .snapshots()
        .map((snap) => snap.docs.map((d) => SchoolClass.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Subject>> watchSubjects(String schoolId) {
    return _db
        .collection(_subjectsPath(schoolId))
        .snapshots()
        .map((snap) => snap.docs.map((d) => Subject.fromMap(d.id, d.data())).toList());
  }

  /// Subjects scoped to one department — this is what makes an HOD only
  /// see their own department's subjects everywhere (marks, syllabus).
  Stream<List<Subject>> watchDepartmentSubjects({
    required String schoolId,
    required String departmentName,
  }) {
    return _db
        .collection(_subjectsPath(schoolId))
        .where('departmentName', isEqualTo: departmentName)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Subject.fromMap(d.id, d.data())).toList());
  }

  Future<void> assignClassTeacher({
    required String schoolId,
    required String classId,
    required String teacherUserId,
  }) async {
    await _db.collection(_classesPath(schoolId)).doc(classId).set(
      {'classTeacherId': teacherUserId},
      SetOptions(merge: true),
    );
    await _db.collection('users').doc(teacherUserId).set(
      {'ownedClassId': classId},
      SetOptions(merge: true),
    );
  }

  Future<int> generateClasses({
    required String schoolId,
    required List<String> levelLabels,
    required List<String> streamNames,
  }) async {
    final batch = _db.batch();
    var count = 0;

    for (final level in levelLabels) {
      if (streamNames.isEmpty) {
        final ref = _db.collection(_classesPath(schoolId)).doc();
        batch.set(ref, SchoolClass(id: ref.id, schoolId: schoolId, name: level, levelLabel: level).toMap());
        count++;
      } else {
        for (final stream in streamNames) {
          final ref = _db.collection(_classesPath(schoolId)).doc();
          batch.set(ref, SchoolClass(
            id: ref.id,
            schoolId: schoolId,
            name: '$level $stream',
            levelLabel: level,
            streamName: stream,
          ).toMap());
          count++;
        }
      }
    }

    await batch.commit();
    return count;
  }
}