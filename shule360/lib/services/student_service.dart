import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  String _studentsPath(String schoolId) => 'schools/$schoolId/students';

  Future<void> registerStudent(Student student) async {
    await _db
        .collection(_studentsPath(student.schoolId))
        .doc(student.id)
        .set(student.toMap());
  }

  Stream<List<Student>> watchStudentsForClass({
    required String schoolId,
    required String classId,
  }) {
    return _db
        .collection(_studentsPath(schoolId))
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Student.fromMap(d.id, d.data())).toList());
  }
}