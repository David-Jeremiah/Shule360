import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/staff_member.dart';

class StaffService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/staff';

  Future<void> addStaff(StaffMember staff) async {
    await _db.collection(_path(staff.schoolId)).doc(staff.id).set(staff.toMap());
  }

  Stream<List<StaffMember>> watchStaff(String schoolId) {
    return _db
        .collection(_path(schoolId))
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => StaffMember.fromMap(d.id, d.data())).toList());
  }
}