import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_record.dart';

class FeeService {
  final _db = FirebaseFirestore.instance;

  String _feesPath(String schoolId) => 'schools/$schoolId/feeRecords';

  Future<void> upsertFeeRecord(FeeRecord record) async {
    await _db.collection(_feesPath(record.schoolId)).doc(record.id).set(record.toMap());
  }

  Stream<List<FeeRecord>> watchFeeRecords({
    required String schoolId,
    required String term,
  }) {
    return _db
        .collection(_feesPath(schoolId))
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => FeeRecord.fromMap(d.id, d.data())).toList());
  }
}