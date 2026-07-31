import 'package:equatable/equatable.dart';

class Subject extends Equatable {
  final String id;
  final String schoolId;
  final String name;
  final EducationLevelScope levelScope;

  const Subject({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.levelScope,
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
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'name': name,
    'levelScope': levelScope.name,
  };

  @override
  List<Object?> get props => [id, schoolId, name, levelScope];
}

enum EducationLevelScope { primary, secondary, both }