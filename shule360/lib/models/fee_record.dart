import 'package:equatable/equatable.dart';

class FeeRecord extends Equatable {
  final String id;
  final String schoolId;
  final String studentId;
  final String term;
  final double amountDue;
  final double amountPaid;
  final DateTime dueDate;

  /// Overrides the school-wide default grace period for this specific student.
  final int? gracePeriodDaysOverride;

  const FeeRecord({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.term,
    required this.amountDue,
    required this.amountPaid,
    required this.dueDate,
    this.gracePeriodDaysOverride,
  });

  double get balance => amountDue - amountPaid;
  bool get isFullyPaid => balance <= 0;

  bool isWithinGracePeriod(int schoolDefaultGraceDays) {
    final graceDays = gracePeriodDaysOverride ?? schoolDefaultGraceDays;
    final graceEnd = dueDate.add(Duration(days: graceDays));
    return DateTime.now().isBefore(graceEnd);
  }

  bool examCardEligible(int schoolDefaultGraceDays) {
    return isFullyPaid || isWithinGracePeriod(schoolDefaultGraceDays);
  }

  factory FeeRecord.fromMap(String id, Map<String, dynamic> map) {
    return FeeRecord(
      id: id,
      schoolId: map['schoolId'] as String,
      studentId: map['studentId'] as String,
      term: map['term'] as String,
      amountDue: (map['amountDue'] as num).toDouble(),
      amountPaid: (map['amountPaid'] as num).toDouble(),
      dueDate: DateTime.parse(map['dueDate'] as String),
      gracePeriodDaysOverride: map['gracePeriodDaysOverride'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'studentId': studentId,
    'term': term,
    'amountDue': amountDue,
    'amountPaid': amountPaid,
    'dueDate': dueDate.toIso8601String(),
    'gracePeriodDaysOverride': gracePeriodDaysOverride,
  };

  @override
  List<Object?> get props => [
    id, schoolId, studentId, term, amountDue, amountPaid, dueDate,
    gracePeriodDaysOverride,
  ];
}