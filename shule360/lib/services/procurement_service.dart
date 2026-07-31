import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/procurement_item.dart';

class ProcurementService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/procurement';

  Future<void> requestItem(ProcurementItem item) async {
    await _db.collection(_path(item.schoolId)).doc(item.id).set(item.toMap());
  }

  Future<void> updateStatus({
    required String schoolId,
    required String itemId,
    required ProcurementStatus status,
    String? supplierName,
  }) async {
    await _db.collection(_path(schoolId)).doc(itemId).set({
      'status': status.name,
      'decidedAt': DateTime.now().toIso8601String(),
      if (supplierName != null) 'supplierName': supplierName,
    }, SetOptions(merge: true));
  }

  Stream<List<ProcurementItem>> watchAll(String schoolId) {
    return _db
        .collection(_path(schoolId))
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ProcurementItem.fromMap(d.id, d.data())).toList());
  }
}