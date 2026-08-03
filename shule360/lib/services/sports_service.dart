import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sports_event.dart';

class SportsService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/sportsEvents';

  Future<void> addEvent(SportsEvent event) async {
    await _db.collection(_path(event.schoolId)).doc(event.id).set(event.toMap());
  }

  Future<void> updateResult(String schoolId, String eventId, String result) async {
    await _db.collection(_path(schoolId)).doc(eventId).set(
      {'resultSummary': result},
      SetOptions(merge: true),
    );
  }

  Stream<List<SportsEvent>> watchAll(String schoolId) {
    return _db
        .collection(_path(schoolId))
        .orderBy('eventDate')
        .snapshots()
        .map((snap) => snap.docs.map((d) => SportsEvent.fromMap(d.id, d.data())).toList());
  }
}