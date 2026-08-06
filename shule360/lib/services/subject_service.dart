import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject.dart';

/// If your project already has a subject_service.dart, delete this one and
/// just wire report_card_editor_screen.dart to that instead — this exists
/// only because no subject-fetching service was visible when this was
/// written, and the report card needs subject *names*, never raw ids.
class SubjectService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _ref(String schoolId) =>
      _db.collection('schools').doc(schoolId).collection('subjects');

  Stream<List<Subject>> watchSubjectsForSchool(String schoolId) {
    return _ref(schoolId).snapshots().map(
          (snap) => snap.docs.map((d) => Subject.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name)),
    );
  }

  Future<List<Subject>> fetchSubjectsForSchool(String schoolId) async {
    final snap = await _ref(schoolId).get();
    return snap.docs.map((d) => Subject.fromMap(d.id, d.data())).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}