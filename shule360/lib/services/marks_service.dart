import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mark_record.dart';

class MarksService {
  final _db = FirebaseFirestore.instance;

  String _marksPath(String schoolId) => 'schools/$schoolId/marks';

  Future<void> submitMark(MarkRecord mark) async {
    await _db.collection(_marksPath(mark.schoolId)).doc(mark.id).set(mark.toMap());
  }

  Stream<List<MarkRecord>> watchMarks({
    required String schoolId,
    required String classId,
    required String subjectId,
    required String term,
  }) {
    return _db
        .collection(_marksPath(schoolId))
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MarkRecord.fromMap(d.id, d.data())).toList());
  }
  Stream<List<MarkRecord>> watchMarksForStudent({
    required String schoolId,
    required String studentId,
    required String term,
  }) {
    return _db
        .collection(_marksPath(schoolId))
        .where('studentId', isEqualTo: studentId)
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MarkRecord.fromMap(d.id, d.data())).toList());
  }
}

