import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';

class AnnouncementService {
  final _db = FirebaseFirestore.instance;
  String _path(String schoolId) => 'schools/$schoolId/announcements';

  Future<void> post(Announcement announcement) async {
    await _db.collection(_path(announcement.schoolId)).doc(announcement.id).set(announcement.toMap());
  }

  Stream<List<Announcement>> watchAll(String schoolId) {
    return _db
        .collection(_path(schoolId))
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Announcement.fromMap(d.id, d.data())).toList());
  }
}