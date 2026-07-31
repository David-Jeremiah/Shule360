import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school_class.dart';
import '../models/subject.dart';

class ClassService {
  final _db = FirebaseFirestore.instance;

  String _classesPath(String schoolId) => 'schools/$schoolId/classes';
  String _subjectsPath(String schoolId) => 'schools/$schoolId/subjects';

  Future<void> createClass(SchoolClass schoolClass) async {
    await _db
        .collection(_classesPath(schoolClass.schoolId))
        .doc(schoolClass.id)
        .set(schoolClass.toMap());
  }

  Future<void> createSubject(Subject subject) async {
    await _db
        .collection(_subjectsPath(subject.schoolId))
        .doc(subject.id)
        .set(subject.toMap());
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
}