import 'package:equatable/equatable.dart';

class StaffMember extends Equatable {
  final String id;
  final String schoolId;
  final String fullName;
  final String position;
  final String? phoneNumber;
  final DateTime hiredOn;
  final bool isActive;

  const StaffMember({
    required this.id,
    required this.schoolId,
    required this.fullName,
    required this.position,
    this.phoneNumber,
    required this.hiredOn,
    this.isActive = true,
  });

  factory StaffMember.fromMap(String id, Map<String, dynamic> map) {
    return StaffMember(
      id: id,
      schoolId: map['schoolId'] as String,
      fullName: map['fullName'] as String,
      position: map['position'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      hiredOn: DateTime.parse(map['hiredOn'] as String),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'fullName': fullName,
    'position': position,
    'phoneNumber': phoneNumber,
    'hiredOn': hiredOn.toIso8601String(),
    'isActive': isActive,
  };

  @override
  List<Object?> get props => [id, schoolId, fullName, position, phoneNumber, hiredOn, isActive];
}