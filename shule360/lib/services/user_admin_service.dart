import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/app_user.dart';
import '../permissions/role.dart';

/// Creates and manages staff accounts WITHOUT signing out the currently
/// logged-in admin. Uses a temporary secondary Firebase app instance for
/// account creation — a standard client-side workaround, since Firebase
/// Auth's normal createUserWithEmailAndPassword call switches the CURRENT
/// session to the new user otherwise.
///
/// IMPORTANT: this is a stopgap for testing. Because it runs entirely on
/// the client, anyone who can open the Manage Users screen can create
/// accounts with any role. Before going live, move account creation into
/// a Cloud Function (Admin SDK) that checks the caller's role server-side.
class UserAdminService {
  final _db = FirebaseFirestore.instance;

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

      await _db.collection('users').doc(uid).set({
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

  /// All staff accounts belonging to a school, as [AppUser] objects — used
  /// by the "existing staff" list view so accounts can be edited after
  /// creation, not just at creation time.
  Stream<List<AppUser>> watchSchoolUsers(String schoolId) {
    return _db
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList());
  }

  /// Same as watchSchoolUsers — kept as a separate name since UserListScreen
  /// calls watchUsers specifically. Both point at the same underlying query.
  Stream<List<AppUser>> watchUsers(String schoolId) => watchSchoolUsers(schoolId);

  /// Distinct department names that exist at this school, derived from
  /// every HOD account's departmentName. Used to populate the "join a
  /// department" dropdown for teachers/class teachers — a department must
  /// have an HOD created first before teachers can be assigned into it.
  Stream<List<String>> watchDepartmentNames(String schoolId) {
    return _db
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: UserRole.hod.storageValue)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => d.data()['departmentName'] as String?)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList());
  }

  /// Every teacher/class teacher account in the school scoped to one
  /// specific department — used by the HOD's "My Teachers" screen.
  Stream<List<AppUser>> watchDepartmentTeachers({
    required String schoolId,
    required String departmentName,
  }) {
    return _db
        .collection('users')
        .where('schoolId', isEqualTo: schoolId)
        .where('departmentName', isEqualTo: departmentName)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => AppUser.fromMap(d.id, d.data()))
        .where((u) => u.role == UserRole.teacher || u.role == UserRole.classTeacher)
        .toList());
  }

  /// Full edit of an existing staff account — name, role, department, and
  /// subjects all at once. Clears departmentName when the new role no
  /// longer needs one (e.g. switching a teacher to Bursar) rather than
  /// leaving stale data behind.
  Future<void> updateStaffAccount({
    required String userId,
    required String fullName,
    required UserRole role,
    String? departmentName,
    List<String> subjectIds = const [],
  }) async {
    await _db.collection('users').doc(userId).set({
      'fullName': fullName,
      'role': role.storageValue,
      'departmentName':
      (departmentName != null && departmentName.isNotEmpty) ? departmentName : FieldValue.delete(),
      'subjectIds': subjectIds,
    }, SetOptions(merge: true));
  }

  /// Used by the HOD's "Assign Subjects" screen — updates just one
  /// teacher's subject list without touching name/role/department.
  Future<void> updateTeacherSubjects({
    required String userId,
    required List<String> subjectIds,
  }) async {
    await _db.collection('users').doc(userId).set(
      {'subjectIds': subjectIds},
      SetOptions(merge: true),
    );
  }

  Future<void> deactivateUser(String uid) async {
    await _db.collection('users').doc(uid).set(
      {'isActive': false},
      SetOptions(merge: true),
    );
  }
}