import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payroll_record.dart';

class PayrollService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/payroll';

  Future<void> generatePayslip(PayrollRecord record) async {
    await _db.collection(_path(record.schoolId)).doc(record.id).set(record.toMap());
  }

  Stream<List<PayrollRecord>> watchPayrollForMonth({
    required String schoolId,
    required String month,
  }) {
    return _db
        .collection(_path(schoolId))
        .where('month', isEqualTo: month)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PayrollRecord.fromMap(d.id, d.data())).toList());
  }
}