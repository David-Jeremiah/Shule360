import 'package:equatable/equatable.dart';

enum EducationLevelScope { primary, secondary, both }

class Subject extends Equatable {
  final String id;
  final String schoolId;
  final String name;
  final EducationLevelScope levelScope;

  /// Which department owns this subject, e.g. "Sciences", "Languages".
  /// Null until an admin assigns it — used to scope what an HOD sees.
  final String? departmentName;

  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.levelScope,
    this.departmentName,
  });

  factory Subject.fromMap(String id, Map<String, dynamic> map) {
    return Subject(
      id: id,
      schoolId: map['schoolId'] as String,
      name: map['name'] as String,
      levelScope: EducationLevelScope.values.firstWhere(
            (l) => l.name == map['levelScope'],
        orElse: () => EducationLevelScope.both,
      ),
      departmentName: map['departmentName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'name': name,
    'levelScope': levelScope.name,
    'departmentName': departmentName,
  };

  @override
  List<Object?> get props => [id, schoolId, name, levelScope, departmentName];
}