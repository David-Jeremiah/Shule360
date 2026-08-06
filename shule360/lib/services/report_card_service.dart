import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_card_mark.dart';

class ReportCardService {
  final _db = FirebaseFirestore.instance;

  String _docId(String studentId, String term) => '${studentId}_$term';

  CollectionReference<Map<String, dynamic>> _ref(String schoolId, String classId) => _db
      .collection('schools')
      .doc(schoolId)
      .collection('classes')
      .doc(classId)
      .collection('reportCards');

  Stream<ReportCardRecord?> watch({
    required String schoolId,
    required String classId,
    required String studentId,
    required String term,
  }) {
    return _ref(schoolId, classId).doc(_docId(studentId, term)).snapshots().map(
          (snap) => snap.exists ? ReportCardRecord.fromMap(snap.data()!) : null,
    );
  }

  Future<ReportCardRecord?> fetch({
    required String schoolId,
    required String classId,
    required String studentId,
    required String term,
  }) async {
    final snap = await _ref(schoolId, classId).doc(_docId(studentId, term)).get();
    return snap.exists ? ReportCardRecord.fromMap(snap.data()!) : null;
  }

  Future<void> save(ReportCardRecord record) {
    return _ref(record.schoolId, record.classId)
        .doc(_docId(record.studentId, record.term))
        .set(record.toMap());
  }
}