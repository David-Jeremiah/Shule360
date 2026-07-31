import 'package:equatable/equatable.dart';

class PayrollRecord extends Equatable {
  final String id;
  final String schoolId;
  final String staffUserId;
  final String month; // e.g. "2026-07"
  final double grossSalary;
  final double deductions;
  final DateTime generatedAt;

  const PayrollRecord({
    required this.id,
    required this.schoolId,
    required this.staffUserId,
    required this.month,
    required this.grossSalary,
    required this.deductions,
    required this.generatedAt,
  });

  double get netSalary => grossSalary - deductions;

  factory PayrollRecord.fromMap(String id, Map<String, dynamic> map) {
    return PayrollRecord(
      id: id,
      schoolId: map['schoolId'] as String,
      staffUserId: map['staffUserId'] as String,
      month: map['month'] as String,
      grossSalary: (map['grossSalary'] as num).toDouble(),
      deductions: (map['deductions'] as num).toDouble(),
      generatedAt: DateTime.parse(map['generatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'staffUserId': staffUserId,
    'month': month,
    'grossSalary': grossSalary,
    'deductions': deductions,
    'generatedAt': generatedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, schoolId, staffUserId, month, grossSalary, deductions, generatedAt];
}