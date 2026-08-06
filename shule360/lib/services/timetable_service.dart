import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/school_class.dart';
import '../models/subject.dart';
import '../models/timetable_slot.dart';

class TimetableService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/timetable';

  /// Returns an error message if this slot shouldn't be created, or null
  /// if it's valid. Two checks:
  /// 1. The teacher must actually be assigned this subject (subjectIds).
  /// 2. The subject's level scope must match the class's stage — a
  ///    Primary-only subject can't be scheduled against a Secondary class
  ///    and vice versa. This is the "P.7 teacher can't be put on an S.4
  ///    slot" guard.
  String? validateSlot({
    required AppUser teacher,
    required Subject subject,
    required SchoolClass schoolClass,
  }) {
    if (!teacher.subjectIds.contains(subject.id)) {
      return '${teacher.fullName} is not assigned to teach ${subject.name}.';
    }

    final classIsPrimary = schoolClass.levelLabel.startsWith('P');
    final classIsSecondary = schoolClass.levelLabel.startsWith('S');

    if (subject.levelScope == EducationLevelScope.primary && classIsSecondary) {
      return '${subject.name} is a Primary-only subject — can\'t assign it to ${schoolClass.name}.';
    }
    if (subject.levelScope == EducationLevelScope.secondary && classIsPrimary) {
      return '${subject.name} is a Secondary-only subject — can\'t assign it to ${schoolClass.name}.';
    }

    return null;
  }

  /// Also checks for a direct time overlap with another slot already
  /// assigned to this class (can't double-book a class) or this teacher
  /// (can't double-book a teacher), on the same day.
  Future<String?> validateNoOverlap({
    required String schoolId,
    required String classId,
    required String teacherId,
    required int dayOfWeek,
    required int startMinutes,
    required int endMinutes,
  }) async {
    final daySlots = await _db
        .collection(_path(schoolId))
        .where('dayOfWeek', isEqualTo: dayOfWeek)
        .get();

    for (final doc in daySlots.docs) {
      final slot = TimetableSlot.fromMap(doc.id, doc.data());
      final overlaps = startMinutes < slot.endMinutes && endMinutes > slot.startMinutes;
      if (!overlaps) continue;
      if (slot.classId == classId) return 'This class already has a slot at this time.';
      if (slot.teacherId == teacherId) return 'This teacher is already booked at this time.';
    }
    return null;
  }

  Future<void> createSlot(TimetableSlot slot) async {
    await _db.collection(_path(slot.schoolId)).doc(slot.id).set(slot.toMap());
  }

  Future<void> deleteSlot(String schoolId, String slotId) async {
    await _db.collection(_path(schoolId)).doc(slotId).delete();
  }

  Stream<List<TimetableSlot>> watchSlotsForClass(String schoolId, String classId) {
    return _db
        .collection(_path(schoolId))
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TimetableSlot.fromMap(d.id, d.data())).toList());
  }

  Stream<List<TimetableSlot>> watchSlotsForTeacher(String schoolId, String teacherId) {
    return _db
        .collection(_path(schoolId))
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TimetableSlot.fromMap(d.id, d.data())).toList());
  }
}