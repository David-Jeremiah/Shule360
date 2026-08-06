import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_card.dart';
import '../models/fee_record.dart';

/// Thrown when someone tries to issue/print a card for a student whose
/// fees aren't cleared. Callers should catch this specifically to show a
/// clear "balance outstanding" message rather than a generic error.
class FeeNotClearedException implements Exception {
  final String message;
  FeeNotClearedException([this.message = 'Fee balance outstanding — exam card cannot be issued.']);
  @override
  String toString() => message;
}

class ExamCardService {
  final _db = FirebaseFirestore.instance;
  String _cardsPath(String schoolId) => 'schools/$schoolId/examCards';
  String _feesPath(String schoolId) => 'schools/$schoolId/feeRecords';

  /// Looks up whether a student's fees are cleared for a term — used both
  /// to gate the UI (show/hide the print button) and internally by
  /// [issueCard] before writing anything.
  Future<bool> checkFeeCleared({
    required String schoolId,
    required String studentId,
    required String term,
  }) async {
    final feeSnap = await _db
        .collection(_feesPath(schoolId))
        .where('studentId', isEqualTo: studentId)
        .where('term', isEqualTo: term)
        .limit(1)
        .get();

    if (feeSnap.docs.isEmpty) return false;

    final fee = FeeRecord.fromMap(feeSnap.docs.first.id, feeSnap.docs.first.data());
    return fee.isFullyPaid || fee.isWithinGracePeriod(21);
  }

  /// Issues (writes) an exam card — but only if fees are cleared. Unlike
  /// the earlier "flag not block" version, this is now a hard block: if
  /// the student's fee balance isn't cleared, this throws
  /// [FeeNotClearedException] and no card document is created at all, so
  /// there is nothing to print.
  Future<ExamCard> issueCard({
    required String schoolId,
    required String studentId,
    required String examName,
    required String term,
    required String issuedByUserId,
  }) async {
    final cleared = await checkFeeCleared(schoolId: schoolId, studentId: studentId, term: term);
    if (!cleared) {
      throw FeeNotClearedException();
    }

    final id = _db.collection(_cardsPath(schoolId)).doc().id;
    final card = ExamCard(
      id: id,
      schoolId: schoolId,
      studentId: studentId,
      examName: examName,
      term: term,
      feeCleared: true,
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