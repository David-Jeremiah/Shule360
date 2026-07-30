import 'package:equatable/equatable.dart';
import '../permissions/role.dart';

class AppUser extends Equatable {
  final String id;
  final String schoolId;
  final UserRole role;
  final String fullName;
  final String? phoneNumber;
  final String? email;

  /// For HOD/teacher: the subject IDs this account is scoped to.
  final List<String> subjectIds;

  /// For class teachers: the class ID they administratively own.
  final String? ownedClassId;

  /// For parents: the student IDs of their own child(ren).
  final List<String> childStudentIds;

  const AppUser({
    required this.id,
    required this.schoolId,
    required this.role,
    required this.fullName,
    this.phoneNumber,
    this.email,
    this.subjectIds = const [],
    this.ownedClassId,
    this.childStudentIds = const [],
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      schoolId: map['schoolId'] as String,
      role: UserRole.fromStorageValue(map['role'] as String),
      fullName: map['fullName'] as String,
      phoneNumber: map['phoneNumber'] as String?,
      email: map['email'] as String?,
      subjectIds: List<String>.from(map['subjectIds'] as List? ?? const []),
      ownedClassId: map['ownedClassId'] as String?,
      childStudentIds:
      List<String>.from(map['childStudentIds'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'role': role.storageValue,
    'fullName': fullName,
    'phoneNumber': phoneNumber,
    'email': email,
    'subjectIds': subjectIds,
    'ownedClassId': ownedClassId,
    'childStudentIds': childStudentIds,
  };

  @override
  List<Object?> get props => [
    id,
    schoolId,
    role,
    fullName,
    phoneNumber,
    email,
    subjectIds,
    ownedClassId,
    childStudentIds,
  ];
}