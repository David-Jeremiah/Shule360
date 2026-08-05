import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/school.dart';

class SchoolService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

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

  Future<void> updateSchool(School school) async {
    await _db.collection('schools').doc(school.id).set(school.toMap(), SetOptions(merge: true));
  }

  /// Uploads a logo image to Firebase Storage and returns its download URL.
  /// Stores it at logos/{schoolId}.<ext>, overwriting any previous logo.
  Future<String> uploadLogo({
    required String schoolId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ref = _storage.ref('logos/$schoolId.$fileExtension');
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }
}