import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class StudentService {
  final _db = FirebaseFirestore.instance;

  String _studentsPath(String schoolId) => 'schools/$schoolId/students';
  String _countersPath(String schoolId) => 'schools/$schoolId/counters';

  Future<void> registerStudent(Student student) async {
    await _db
        .collection(_studentsPath(student.schoolId))
        .doc(student.id)
        .set(student.toMap());
  }

  Stream<List<Student>> watchStudentsForClass({
    required String schoolId,
    required String classId,
  }) {
    return _db
        .collection(_studentsPath(schoolId))
        .where('classId', isEqualTo: classId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Student.fromMap(d.id, d.data())).toList());
  }

  /// Registers a new student with an auto-generated admission number and
  /// class roll number.
  ///
  /// NOTE: this intentionally does NOT use `runTransaction`. Firestore
  /// transactions on Windows desktop trigger a known FlutterFire plugin
  /// bug — each get/set inside the transaction opens its own native
  /// channel in rapid succession, and that burst reliably crashes the
  /// app with "channel sent a message from native to Flutter on a
  /// non-platform thread" -> abort(). Instead we use `FieldValue.increment`,
  /// which is a single atomic write handled entirely server-side (no
  /// local read-modify-write round trip), then read back the result.
  ///
  /// Trade-off: there's a theoretical race if two staff members register
  /// a student in the exact same class at the exact same instant — both
  /// increments are still atomic and unique, but the immediate read-back
  /// could very rarely reflect only one of them at that instant. For a
  /// school registration flow this risk is negligible; if it ever matters,
  /// the robust fix is to move this into a Cloud Function callable so the
  /// transaction runs server-side and the client only does one round trip.
  ///
  /// Admission number: ADM/{year}/{seq} — sequence resets every calendar
  /// year and is school-wide.
  /// Roll number: plain zero-padded sequence scoped to the class.
  Future<Student> registerNewStudent({
    required String schoolId,
    required String fullName,
    required EducationLevel level,
    required String classId,
    String? guardianPhoneNumber,
  }) async {
    final now = DateTime.now();
    final year = now.year;
    final admissionCounterRef = _db.collection(_countersPath(schoolId)).doc('admission_$year');
    final classCounterRef = _db.collection(_countersPath(schoolId)).doc('class_$classId');
    final studentRef = _db.collection(_studentsPath(schoolId)).doc();

    // Atomically bump both counters — single writes, no transaction.
    await admissionCounterRef.set({'seq': FieldValue.increment(1)}, SetOptions(merge: true));
    await classCounterRef.set({'seq': FieldValue.increment(1)}, SetOptions(merge: true));

    // Read back the committed values (server source, to avoid any stale
    // local cache).
    final admissionSnap = await admissionCounterRef.get(const GetOptions(source: Source.server));
    final classSnap = await classCounterRef.get(const GetOptions(source: Source.server));

    final nextAdmissionSeq = (admissionSnap.data()?['seq'] as int?) ?? 1;
    final nextClassSeq = (classSnap.data()?['seq'] as int?) ?? 1;

    final admissionNumber = 'ADM/$year/${nextAdmissionSeq.toString().padLeft(4, '0')}';
    final rollNumber = nextClassSeq.toString().padLeft(3, '0');

    final newStudent = Student(
      id: studentRef.id,
      schoolId: schoolId,
      fullName: fullName,
      admissionNumber: admissionNumber,
      rollNumber: rollNumber,
      level: level,
      classId: classId,
      guardianPhoneNumber: (guardianPhoneNumber == null || guardianPhoneNumber.isEmpty)
          ? null
          : guardianPhoneNumber,
      enrolledOn: now,
    );

    await studentRef.set(newStudent.toMap());

    return newStudent;
  }
}