import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/school.dart';

class SchoolService {
  final _db = FirebaseFirestore.instance;

  Future<School> fetchSchool(String schoolId) async {
    final doc = await _db.collection('schools').doc(schoolId).get();
    return School.fromMap(doc.id, doc.data()!);
  }

  Stream<School> watchSchool(String schoolId) {
    return _db.collection('schools').doc(schoolId).snapshots().map(
          (doc) => School.fromMap(doc.id, doc.data() ?? {}),
    );
  }

  Future<void> updateBranding({
    required String schoolId,
    String? logoUrl,
    String? primaryColorHex,
  }) async {
    await _db.collection('schools').doc(schoolId).set({
      if (logoUrl != null) 'logoUrl': logoUrl,
      if (primaryColorHex != null) 'primaryColorHex': primaryColorHex,
    }, SetOptions(merge: true));
  }
}