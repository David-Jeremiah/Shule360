import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_card.dart';
import '../models/fee_record.dart';

class ExamCardService {
  final _db = FirebaseFirestore.instance;
  String _cardsPath(String schoolId) => 'schools/$schoolId/examCards';
  String _feesPath(String schoolId) => 'schools/$schoolId/feeRecords';

  /// Checks fee status for the student/term, then issues the card
  /// regardless of clearance — [feeCleared] is recorded as a flag rather
  /// than a hard block, per the "flag not block" policy (see spec Section
  /// 14 — confirm this with the team before shipping; a hard-block variant
  /// would simply return early instead of proceeding when false).
  Future<ExamCard> issueCard({
    required String schoolId,
    required String studentId,
    required String examName,
    required String term,
    required String issuedByUserId,
  }) async {
    final feeSnap = await _db
        .collection(_feesPath(schoolId))
        .where('studentId', isEqualTo: studentId)
        .where('term', isEqualTo: term)
        .limit(1)
        .get();

    bool feeCleared = false;
    if (feeSnap.docs.isNotEmpty) {
      final fee = FeeRecord.fromMap(feeSnap.docs.first.id, feeSnap.docs.first.data());
      feeCleared = fee.isFullyPaid || fee.isWithinGracePeriod(21);
    }

    final id = _db.collection('placeholder').doc().id;
    final card = ExamCard(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      examName: examName,
      term: term,
      feeCleared: feeCleared,
      issuedAt: DateTime.now(),
      issuedByUserId: issuedByUserId,
    );
    await _db.collection(_cardsPath(schoolId)).doc(id).set(card.toMap());
    return card;
  }

  Stream<List<ExamCard>> watchCardsForClass({
    required String schoolId,
    required String term,
  }) {
    return _db
        .collection(_cardsPath(schoolId))
        .where('term', isEqualTo: term)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ExamCard.fromMap(d.id, d.data())).toList());
  }
}