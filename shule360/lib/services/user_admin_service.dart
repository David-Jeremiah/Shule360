import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../permissions/role.dart';

/// Creates a new staff account WITHOUT signing out the currently logged-in
/// admin. Uses a temporary secondary Firebase app instance — a standard
/// client-side workaround, since Firebase Auth's normal
/// createUserWithEmailAndPassword call switches the CURRENT session to the
/// new user otherwise.
///
/// IMPORTANT: this is a stopgap for testing. Because it runs entirely on
/// the client, anyone who can open this screen can create accounts with
/// any role. Before going live, move this logic into a Cloud Function
/// (using the Admin SDK) that checks the caller's role server-side before
/// creating the account.
class UserAdminService {
  Future<String> createStaffAccount({
    required String email,
    required String password,
    required String fullName,
    required String schoolId,
    required UserRole role,
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
      });

      await tempAuth.signOut();
      return uid;
    } finally {
      await tempApp.delete();
    }
  }
}