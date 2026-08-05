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

  /// Subjects belonging to one department only — used to scope what an
  /// HOD sees (assigning teachers, syllabus coverage, targets). Filters
  /// client-side rather than a Firestore where-clause so callers with no
  /// department set (departmentName null) don't need a composite index.
  Stream<List<Subject>> watchDepartmentSubjects({
    required String schoolId,
    required String departmentName,
  }) {
    return watchSubjects(schoolId).map(
          (subjects) => subjects.where((s) => s.departmentName == departmentName).toList(),
    );
  }

  /// Sets or clears which department owns a subject. Pass null/empty to
  /// unassign it back to "no department".
  Future<void> updateSubjectDepartment({
    required String schoolId,
    required String subjectId,
    required String? departmentName,
  }) async {
    await _db.collection(_subjectsPath(schoolId)).doc(subjectId).set(
      {
        'departmentName':
        (departmentName != null && departmentName.isNotEmpty) ? departmentName : FieldValue.delete(),
      },
      SetOptions(merge: true),
    );
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

  /// Assigns a subject teacher for a specific class — used by the
  /// timetable module. Distinct from assignClassTeacher (the homeroom
  /// teacher); a class can have many subject teachers but one class teacher.
  Future<void> assignSubjectTeacher({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String teacherUserId,
  }) async {
    await _db.collection(_classesPath(schoolId)).doc(classId).set(
      {
        'subjectTeacherIds.$subjectId': teacherUserId,
      },
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