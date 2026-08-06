import '../models/report_card_mark.dart';

/// Generates a first-draft remark from a student's performance so a
/// teacher can hit "Suggest" and then tweak wording instead of writing
/// from scratch every time — never saved automatically, always editable.
///
/// This is rule-based (no external API call, no cost, works offline).
/// If you later want genuinely AI-written comments, swap the body of
/// these three methods for a call to your own backend — don't call an
/// LLM API directly from the Flutter app, since that would mean shipping
/// an API key inside the app binary.
class CommentSuggestionService {
  String suggestSubjectComment(double average, {String? subjectName}) {
    final band = gradeFor(average);
    final subject = subjectName != null ? ' in $subjectName' : '';
    switch (band.descriptor) {
      case 'Excellent':
        return 'Excellent performance$subject, keep it up.';
      case 'Very Good':
        return 'Very good performance$subject this term.';
      case 'Good':
        return 'Good effort$subject — aim higher next term.';
      case 'Fairly Good':
      case 'Fair':
        return 'Fair performance$subject, needs more practice.';
      case 'Pass':
      case 'Weak Pass':
        return 'Passed$subject, but needs to work much harder.';
      default:
        return 'Needs serious improvement$subject and extra support.';
    }
  }

  String suggestOverallComment(double overallAverage) {
    final band = gradeFor(overallAverage);
    if (band.descriptor == 'Excellent' || band.descriptor == 'Very Good') {
      return 'A dedicated learner with excellent discipline and hard work this term.';
    }
    if (band.descriptor == 'Good' || band.descriptor == 'Fairly Good' || band.descriptor == 'Fair') {
      return 'A promising learner. Encourage more revision at home.';
    }
    return 'Needs closer supervision and extra academic support next term.';
  }

  String suggestConductComment() => 'Well disciplined and hard working.';
}