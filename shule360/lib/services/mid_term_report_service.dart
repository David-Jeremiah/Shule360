import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mark_record.dart';

class SubjectPassRate {
  final String subjectId;
  final int totalStudents;
  final int passCount;
  double get passRate => totalStudents == 0 ? 0 : (passCount / totalStudents) * 100;

  SubjectPassRate({required this.subjectId, required this.totalStudents, required this.passCount});
}

class MidTermReportService {
  final _db = FirebaseFirestore.instance;

  /// Manually triggered by the DOS. Pulls all mid-term marks for the class
  /// and computes a pass rate per subject. [passMark] is the percentage
  /// threshold to count as a pass (configurable per school/subject later).
  Future<List<SubjectPassRate>> generateMidTermReport({
    required String schoolId,
    required String classId,
    required String term,
    double passMark = 40,
  }) async {
    final snap = await _db
        .collection('schools/$schoolId/marks')
        .where('classId', isEqualTo: classId)
        .where('term', isEqualTo: term)
        .where('period', isEqualTo: 'midTerm')
        .get();

    final marks = snap.docs.map((d) => MarkRecord.fromMap(d.id, d.data())).toList();
    final bySubject = <String, List<MarkRecord>>{};
    for (final m in marks) {
      bySubject.putIfAbsent(m.subjectId, () => []).add(m);
    }

    return bySubject.entries.map((entry) {
      final subjectMarks = entry.value;
      final passCount = subjectMarks.where((m) => m.percentage >= passMark).length;
      return SubjectPassRate(
        subjectId: entry.key,
        totalStudents: subjectMarks.length,
        passCount: passCount,
      );
    }).toList();
  }
}