/// Subject lists aligned to Uganda's curriculum, split by stage since
/// lower and upper primary genuinely differ (thematic curriculum vs the
/// PLE-examinable subjects).
class UgandaSubjects {
  UgandaSubjects._();

  /// P.1–P.3 — thematic curriculum.
  static const lowerPrimary = <String>[
    'Literacy One (Local Language)',
    'Literacy Two (English)',
    'Numeracy',
    'Life Skills',
    'Religious Education',
    'Physical Education',
  ];

  /// P.4–P.7 — the 4 PLE-examinable subjects, plus common non-examined ones.
  static const upperPrimary = <String>[
    'English',
    'Mathematics',
    'Science',
    'Social Studies',
    'Religious Education',
    'Local Language',
    'Physical Education',
  ];

  /// Alias used by ManageClassesScreen's preset-seeding button. Kept
  /// separate from allPrimary (a Set-deduped union) so callers that just
  /// want "everything for a primary school" get a stable ordered list.
  static const primary = <String>[
    ...lowerPrimary,
    ...upperPrimary,
  ];

  /// O-Level, S.1–S.4.
  static const secondary = <String>[
    'English Language',
    'Mathematics',
    'Biology',
    'Physics',
    'Chemistry',
    'History',
    'Geography',
    'Christian Religious Education',
    'Islamic Religious Education',
    'Literature in English',
    'Kiswahili',
    'Luganda',
    'Agriculture',
    'Commerce',
    'Computer Studies',
    'Entrepreneurship Education',
    'Fine Art',
    'Music, Dance and Drama',
    'Physical Education',
    'Technical Drawing',
    'Food and Nutrition',
  ];

  /// A-Level (S.5–S.6) common subject combinations. Not exhaustive —
  /// schools can add custom combos manually via "Add one at a time".
  static const aLevel = <String>[
    'General Paper',
    'Sub-Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'Economics',
    'Geography',
    'History',
    'Divinity',
    'Islamic Religious Education',
    'Literature in English',
    'Entrepreneurship',
    'Computer Science',
    'Agriculture',
    'Fine Art',
  ];

  static List<String> get allPrimary => {...lowerPrimary, ...upperPrimary}.toList();
}