/// Report-card-specific marks model. Kept separate from whatever
/// `MarkRecord` your Enter Marks screen uses day-to-day — this one stores
/// every assessment component (BOT/MT/EOT/HW/T1/MOT, or whatever your
/// school uses) for a single subject on a single report card, plus the
/// subject's own remark and the marking teacher's initials, so it can be
/// printed straight onto the report.
class ReportCardSubjectMark {
  final String subjectId;
  final String subjectName; // resolved name — never the raw code/id, for printing
  final Map<String, double> componentScores; // e.g. {'BOT': 85, 'MT': 82, 'EOT': 71, 'HW': 90, 'T1': 85, 'MOT': 90}
  final String? comment; // subject-level remark, e.g. "Excellent work"
  final String? teacherInitials;

  const ReportCardSubjectMark({
    required this.subjectId,
    required this.subjectName,
    required this.componentScores,
    this.comment,
    this.teacherInitials,
  });

  double get average => componentScores.isEmpty
      ? 0
      : componentScores.values.reduce((a, b) => a + b) / componentScores.length;

  ReportCardSubjectMark copyWith({
    Map<String, double>? componentScores,
    String? comment,
    String? teacherInitials,
  }) {
    return ReportCardSubjectMark(
      subjectId: subjectId,
      subjectName: subjectName,
      componentScores: componentScores ?? this.componentScores,
      comment: comment ?? this.comment,
      teacherInitials: teacherInitials ?? this.teacherInitials,
    );
  }

  Map<String, dynamic> toMap() => {
    'subjectId': subjectId,
    'subjectName': subjectName,
    'componentScores': componentScores,
    'comment': comment,
    'teacherInitials': teacherInitials,
  };

  factory ReportCardSubjectMark.fromMap(Map<String, dynamic> map) => ReportCardSubjectMark(
    subjectId: map['subjectId'] as String,
    subjectName: map['subjectName'] as String? ?? map['subjectId'] as String,
    componentScores: Map<String, double>.from(
      ((map['componentScores'] as Map?) ?? {}).map((k, v) => MapEntry(k as String, (v as num).toDouble())),
    ),
    comment: map['comment'] as String?,
    teacherInitials: map['teacherInitials'] as String?,
  );
}

/// One row of the grading-scale legend printed at the bottom of the report
/// (e.g. D1: 85-100, Excellent).
class GradingBand {
  final String grade;
  final int minScore;
  final int maxScore;
  final String descriptor;

  const GradingBand({
    required this.grade,
    required this.minScore,
    required this.maxScore,
    required this.descriptor,
  });

  bool contains(double score) => score >= minScore && score <= maxScore;
}

class ReportCardGrade {
  final String grade;
  final String descriptor;
  const ReportCardGrade(this.grade, this.descriptor);
}

/// Default UNEB-style scale matching the sample report. Swap this out
/// (or make it per-school, e.g. read off School Settings) if a school
/// uses a different scale — grading is entirely driven by this list.
const kDefaultGradingScale = <GradingBand>[
  GradingBand(grade: 'D1', minScore: 85, maxScore: 100, descriptor: 'Excellent'),
  GradingBand(grade: 'D2', minScore: 80, maxScore: 84, descriptor: 'Very Good'),
  GradingBand(grade: 'C3', minScore: 70, maxScore: 79, descriptor: 'Good'),
  GradingBand(grade: 'C4', minScore: 65, maxScore: 69, descriptor: 'Fairly Good'),
  GradingBand(grade: 'C5', minScore: 58, maxScore: 64, descriptor: 'Fair'),
  GradingBand(grade: 'C6', minScore: 54, maxScore: 57, descriptor: 'Fair'),
  GradingBand(grade: 'P7', minScore: 50, maxScore: 53, descriptor: 'Pass'),
  GradingBand(grade: 'P8', minScore: 45, maxScore: 49, descriptor: 'Weak Pass'),
  GradingBand(grade: 'F9', minScore: 0, maxScore: 44, descriptor: 'Fail'),
];

ReportCardGrade gradeFor(double score, [List<GradingBand> scale = kDefaultGradingScale]) {
  for (final band in scale) {
    if (band.contains(score)) return ReportCardGrade(band.grade, band.descriptor);
  }
  return const ReportCardGrade('-', '-');
}

/// The three free-text remarks printed under the marks table. Each can be
/// typed, AI-suggested (see CommentSuggestionService), or edited after —
/// they're just plain strings, no locking between the two.
class ReportCardComments {
  final String? classTeacherComment;
  final String? conductComment;
  final String? headTeacherComment;

  const ReportCardComments({
    this.classTeacherComment,
    this.conductComment,
    this.headTeacherComment,
  });

  ReportCardComments copyWith({
    String? classTeacherComment,
    String? conductComment,
    String? headTeacherComment,
  }) {
    return ReportCardComments(
      classTeacherComment: classTeacherComment ?? this.classTeacherComment,
      conductComment: conductComment ?? this.conductComment,
      headTeacherComment: headTeacherComment ?? this.headTeacherComment,
    );
  }

  Map<String, dynamic> toMap() => {
    'classTeacherComment': classTeacherComment,
    'conductComment': conductComment,
    'headTeacherComment': headTeacherComment,
  };

  factory ReportCardComments.fromMap(Map<String, dynamic> map) => ReportCardComments(
    classTeacherComment: map['classTeacherComment'] as String?,
    conductComment: map['conductComment'] as String?,
    headTeacherComment: map['headTeacherComment'] as String?,
  );
}

/// The full persisted record for one student's report card in one term —
/// everything the PDF needs, saved once so re-opening the editor or
/// re-printing later doesn't lose anything.
class ReportCardRecord {
  final String schoolId;
  final String classId;
  final String studentId;
  final String term;
  final List<ReportCardSubjectMark> subjectMarks;
  final ReportCardComments comments;
  final String? gender;
  final String? studentPhotoUrl;
  final int? classPosition;
  final int? classSize;
  final DateTime? termEndDate;
  final DateTime? nextTermStartDate;
  final double? feesBalance;

  const ReportCardRecord({
    required this.schoolId,
    required this.classId,
    required this.studentId,
    required this.term,
    required this.subjectMarks,
    this.comments = const ReportCardComments(),
    this.gender,
    this.studentPhotoUrl,
    this.classPosition,
    this.classSize,
    this.termEndDate,
    this.nextTermStartDate,
    this.feesBalance,
  });

  double get overallAverage => subjectMarks.isEmpty
      ? 0
      : subjectMarks.map((m) => m.average).reduce((a, b) => a + b) / subjectMarks.length;

  double get overallTotal => subjectMarks.fold(0.0, (sum, m) => sum + m.average);

  ReportCardRecord copyWith({
    List<ReportCardSubjectMark>? subjectMarks,
    ReportCardComments? comments,
    String? gender,
    String? studentPhotoUrl,
    int? classPosition,
    int? classSize,
    DateTime? termEndDate,
    DateTime? nextTermStartDate,
    double? feesBalance,
  }) {
    return ReportCardRecord(
      schoolId: schoolId,
      classId: classId,
      studentId: studentId,
      term: term,
      subjectMarks: subjectMarks ?? this.subjectMarks,
      comments: comments ?? this.comments,
      gender: gender ?? this.gender,
      studentPhotoUrl: studentPhotoUrl ?? this.studentPhotoUrl,
      classPosition: classPosition ?? this.classPosition,
      classSize: classSize ?? this.classSize,
      termEndDate: termEndDate ?? this.termEndDate,
      nextTermStartDate: nextTermStartDate ?? this.nextTermStartDate,
      feesBalance: feesBalance ?? this.feesBalance,
    );
  }

  Map<String, dynamic> toMap() => {
    'schoolId': schoolId,
    'classId': classId,
    'studentId': studentId,
    'term': term,
    'subjectMarks': subjectMarks.map((m) => m.toMap()).toList(),
    'comments': comments.toMap(),
    'gender': gender,
    'studentPhotoUrl': studentPhotoUrl,
    'classPosition': classPosition,
    'classSize': classSize,
    'termEndDate': termEndDate?.toIso8601String(),
    'nextTermStartDate': nextTermStartDate?.toIso8601String(),
    'feesBalance': feesBalance,
  };

  factory ReportCardRecord.fromMap(Map<String, dynamic> map) => ReportCardRecord(
    schoolId: map['schoolId'] as String,
    classId: map['classId'] as String,
    studentId: map['studentId'] as String,
    term: map['term'] as String,
    subjectMarks: ((map['subjectMarks'] as List?) ?? [])
        .map((m) => ReportCardSubjectMark.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList(),
    comments: map['comments'] != null
        ? ReportCardComments.fromMap(Map<String, dynamic>.from(map['comments'] as Map))
        : const ReportCardComments(),
    gender: map['gender'] as String?,
    studentPhotoUrl: map['studentPhotoUrl'] as String?,
    classPosition: map['classPosition'] as int?,
    classSize: map['classSize'] as int?,
    termEndDate: map['termEndDate'] != null ? DateTime.parse(map['termEndDate'] as String) : null,
    nextTermStartDate:
    map['nextTermStartDate'] != null ? DateTime.parse(map['nextTermStartDate'] as String) : null,
    feesBalance: (map['feesBalance'] as num?)?.toDouble(),
  );

  factory ReportCardRecord.blank({
    required String schoolId,
    required String classId,
    required String studentId,
    required String term,
    required List<ReportCardSubjectMark> subjectMarks,
  }) =>
      ReportCardRecord(
        schoolId: schoolId,
        classId: classId,
        studentId: studentId,
        term: term,
        subjectMarks: subjectMarks,
      );
}