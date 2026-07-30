enum UserRole {
  headTeacher,
  director,
  dos, // Director of Studies
  hod, // Head of Department
  classTeacher,
  teacher,
  bursar,
  hrOfficer,
  parent,
  student;

  String get storageValue => switch (this) {
    UserRole.headTeacher => 'head_teacher',
    UserRole.director => 'director',
    UserRole.dos => 'dos',
    UserRole.hod => 'hod',
    UserRole.classTeacher => 'class_teacher',
    UserRole.teacher => 'teacher',
    UserRole.bursar => 'bursar',
    UserRole.hrOfficer => 'hr_officer',
    UserRole.parent => 'parent',
    UserRole.student => 'student',
  };

  static UserRole fromStorageValue(String value) {
    return UserRole.values.firstWhere(
          (r) => r.storageValue == value,
      orElse: () => throw ArgumentError('Unknown role: $value'),
    );
  }

  String get displayName => switch (this) {
    UserRole.headTeacher => 'Head Teacher',
    UserRole.director => 'Director',
    UserRole.dos => 'Director of Studies',
    UserRole.hod => 'Head of Department',
    UserRole.classTeacher => 'Class Teacher',
    UserRole.teacher => 'Teacher',
    UserRole.bursar => 'Bursar',
    UserRole.hrOfficer => 'HR Officer',
    UserRole.parent => 'Parent',
    UserRole.student => 'Student',
  };
}