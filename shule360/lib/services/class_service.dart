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

  Future<void> createSubject(Subject subject) async {
    await _db.collection(_subjectsPath(subject.schoolId)).doc(subject.id).set(subject.toMap());
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

  /// Generates one class per level label, optionally crossed with each
  /// stream name (e.g. 4 levels x 2 streams = 8 classes). If [streamNames]
  /// is empty, generates one flat class per level with no stream suffix —
  /// this is the "school doesn't use streams" path.
  Future<int> generateClasses({
    required String schoolId,
    required List<String> levelLabels,
    required List<String> streamNames,
  }) async {
    final batch = _db.batch();
    var count = 0;

    for (final level in levelLabels) {
      if (streamNames.isEmpty) {
        final id = _db.collection(_classesPath(schoolId)).doc().id;
        final ref = _db.collection(_classesPath(schoolId)).doc(id);
        batch.set(ref, SchoolClass(
          id: id,
          schoolId: schoolId,
          name: level,
          levelLabel: level,
        ).toMap());
        count++;
      } else {
        for (final stream in streamNames) {
          final id = _db.collection(_classesPath(schoolId)).doc().id;
          final ref = _db.collection(_classesPath(schoolId)).doc(id);
          batch.set(ref, SchoolClass(
            id: id,
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