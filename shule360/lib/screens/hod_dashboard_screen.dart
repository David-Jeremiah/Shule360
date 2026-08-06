import 'package:flutter/material.dart';
import '../models/app_user.dart';
import 'select_class_subject_screen.dart';
import 'enter_marks_screen.dart';
import 'syllabus_tracker_screen.dart';
import 'mid_term_report_screen.dart';
import 'hod_my_teachers_screen.dart';
import 'hod_review_syllabus_screen.dart';
import 'hod_set_target_screen.dart';
import 'teacher_attendance_screen.dart';
import '../widgets/sign_out_button.dart';

class HodDashboardScreen extends StatelessWidget {
  final AppUser user;
  final String term;

  const HodDashboardScreen({super.key, required this.user, required this.term});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(user.departmentName != null ? 'Head of ${user.departmentName}' : 'HOD Dashboard'),
        actions: const [SignOutButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome, ${user.fullName}', style: Theme.of(context).textTheme.headlineSmall),
                if (user.subjectIds.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No subjects assigned to your own teaching yet — ask your admin to assign some before you can enter marks or track syllabus yourself.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 20),

                Text('Your Teaching', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Check In to Class'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(currentUser: user)),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Enter Marks'),
                  onPressed: user.subjectIds.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class & Subject',
                        departmentFilter: user.departmentName,
                        allowedSubjectIds: user.subjectIds,
                        onSelected: (classId, subjectId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EnterMarksScreen(
                                currentUser: user, classId: classId, subjectId: subjectId, term: term,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.checklist),
                  label: const Text('Syllabus Coverage'),
                  onPressed: user.subjectIds.isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class & Subject',
                        departmentFilter: user.departmentName,
                        allowedSubjectIds: user.subjectIds,
                        onSelected: (classId, subjectId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SyllabusTrackerScreen(
                                currentUser: user, classId: classId, subjectId: subjectId, term: term,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text('Department Oversight', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.people),
                  label: const Text('My Department Teachers'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => HodMyTeachersScreen(currentUser: user)),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.fact_check),
                  label: const Text('Review Syllabus Submissions'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class & Subject to Review',
                        departmentFilter: user.departmentName,
                        onSelected: (classId, subjectId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HodReviewSyllabusScreen(
                                currentUser: user, classId: classId, subjectId: subjectId, term: term,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.flag),
                  label: const Text('Set Syllabus Targets'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class & Subject',
                        departmentFilter: user.departmentName,
                        onSelected: (classId, subjectId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HodSetTargetScreen(
                                currentUser: user, classId: classId, subjectId: subjectId, term: term,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.analytics),
                  label: const Text('Department Pass/Fail Report'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class',
                        departmentFilter: user.departmentName,
                        onSelected: (classId, _) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MidTermReportScreen(currentUser: user, classId: classId, term: term),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}