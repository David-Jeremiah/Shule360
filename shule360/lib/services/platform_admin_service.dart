import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school.dart';
import '../models/app_user.dart';

class PlatformAdminService {
  final _db = FirebaseFirestore.instance;

  Stream<List<School>> watchAllSchools() {
    return _db
        .collection('schools')
        .snapshots()
        .map((snap) => snap.docs.map((d) => School.fromMap(d.id, d.data())).toList());
  }

  Future<String> createSchool(School school) async {
    final ref = _db.collection('schools').doc();
    await ref.set(school.toMap());
    return ref.id;
  }

  Future<void> updateSchool(School school) async {
    await _db.collection('schools').doc(school.id).set(school.toMap(), SetOptions(merge: true));
  }

  Stream<List<Map<String, dynamic>>> watchPlatformTeam() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'platform_admin')
        .snapshots()
        .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Every person enrolled at a given school — staff, students, parents.
  Stream<List<AppUser>> watchSchoolUsers(String schoolId) {
    return _db
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) {
      final users = snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
      users.sort((a, b) => a.fullName.compareTo(b.fullName));
      return users;
    });
  }
}