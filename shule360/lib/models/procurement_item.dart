import 'package:equatable/equatable.dart';

enum ProcurementStatus { requested, approved, rejected, purchased }

class ProcurementItem extends Equatable {
  final String id;
  final String schoolId;
  final String itemName;
  final int quantity;
  final double estimatedCost;
  final String requestedByUserId;
  final ProcurementStatus status;
  final String? supplierName;
  final DateTime requestedAt;
  final DateTime? decidedAt;

  const ProcurementItem({
    required this.id,
    required this.schoolId,
    required this.itemName,
    required this.quantity,
    required this.estimatedCost,
    required this.requestedByUserId,
    this.status = ProcurementStatus.requested,
    this.supplierName,
    required this.requestedAt,
    this.decidedAt,
  });

  factory ProcurementItem.fromMap(String id, Map<String, dynamic> map) {
    return ProcurementItem(
      id: id,
      schoolId: map['schoolId'] as String,
      itemName: map['itemName'] as String,
      quantity: map['quantity'] as int,
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
      requestedByUserId: map['requestedByUserId'] as String,
      status: ProcurementStatus.values.firstWhere((s) => s.name == map['status']),
      supplierName: map['supplierName'] as String?,
      requestedAt: DateTime.parse(map['requestedAt'] as String),
      decidedAt: map['decidedAt'] != null ? DateTime.parse(map['decidedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'itemName': itemName,
    'quantity': quantity,
    'estimatedCost': estimatedCost,
    'requestedByUserId': requestedByUserId,
    'status': status.name,
    'supplierName': supplierName,
    'requestedAt': requestedAt.toIso8601String(),
    'decidedAt': decidedAt?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id, schoolId, itemName, quantity, estimatedCost, requestedByUserId,
    status, supplierName, requestedAt, decidedAt,
  ];
}