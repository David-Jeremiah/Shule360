import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';
import '../permissions/role.dart';

class UserAdminService {
  Future<String> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required String schoolId,
    required UserRole role,
    String? departmentName,
    List<String>? subjectIds,
  }) async {
    final tempApp = await Firebase.initializeApp(
      name: 'tempAdminApp-${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'schoolId': schoolId,
        'role': role.storageValue,
        'fullName': fullName,
        if (departmentName != null && departmentName.isNotEmpty) 'departmentName': departmentName,
        if (subjectIds != null && subjectIds.isNotEmpty) 'subjectIds': subjectIds,
      });

      await tempAuth.signOut();
      return uid;
    } finally {
      await tempApp.delete();
    }
  }

  /// All staff/users belonging to a school, sorted by name.
  Stream<List<AppUser>> watchUsers(String schoolId) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) {
      final users = snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList();
      users.sort((a, b) => a.fullName.compareTo(b.fullName));
      return users;
    });
  }

  /// Distinct department names, sourced from existing HOD accounts.
  /// Used so teachers/class teachers can be assigned into a department
  /// that already has a head, instead of typing a fresh one.
  Stream<List<String>> watchDepartmentNames(String schoolId) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: UserRole.hod.storageValue)
        .snapshots()
        .map((snap) {
      final names = snap.docs
          .map((d) => d.data()['departmentName'] as String?)
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      names.sort();
      return names;
    });
  }

  /// Teachers/class teachers who belong to a given department name.
  Stream<List<AppUser>> watchDepartmentTeachers({
    required String schoolId,
    required String departmentName,
  }) {
    return FirebaseFirestore.instance
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('departmentName', isEqualTo: departmentName)
        .snapshots()
        .map((snap) {
      final users = snap.docs
          .map((d) => AppUser.fromMap(d.id, d.data()))
          .where((u) => u.role == UserRole.teacher || u.role == UserRole.classTeacher)
          .toList();
      users.sort((a, b) => a.fullName.compareTo(b.fullName));
      return users;
    });
  }

  /// Full profile edit (name, role, department, subjects). Does NOT touch
  /// email/password — that stays in Firebase Auth and isn't editable here.
  Future<void> updateStaffAccount({
    required String userId,
    required String fullName,
    required UserRole role,
    String? departmentName,
    List<String>? subjectIds,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fullName': fullName,
      'role': role.storageValue,
      'departmentName': departmentName,
      'subjectIds': subjectIds ?? [],
    });
  }

  /// Lightweight update for HODs assigning subjects to their own
  /// department's teachers — doesn't touch role/department/name.
  Future<void> updateTeacherSubjects({
    required String userId,
    required List<String> subjectIds,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'subjectIds': subjectIds,
    });
  }
}