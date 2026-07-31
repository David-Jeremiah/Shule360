import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';
import '../widgets/role_gated_action.dart';
import 'register_student_screen.dart';
import 'manage_classes_screen.dart';
import 'select_class_subject_screen.dart';
import 'enter_marks_screen.dart';
import 'fee_management_screen.dart';
import 'teacher_attendance_screen.dart';
import 'syllabus_tracker_screen.dart';
import 'mid_term_report_screen.dart';
import 'payroll_screen.dart';
import 'procurement_screen.dart';
import 'report_card_screen.dart';
import 'staff_management_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;

  const HomeScreen({super.key, required this.user});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: term is hardcoded for now — replace with a real term selector
    // once school-level term configuration exists.
    const currentTerm = '2026-T2';

    return Scaffold(
      appBar: AppBar(
        title: Text('Shule360 — ${user.role.displayName}'),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
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
                const SizedBox(height: 4),
                Text('You are signed in as: ${user.role.displayName}'),
                const SizedBox(height: 24),

                RoleGatedAction(
                  role: user.role,
                  capability: Capability.manageOwnClassStudents,
                  icon: Icons.person_add,
                  label: 'Register Student',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => RegisterStudentScreen(currentUser: user)),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.manageTimetable,
                  icon: Icons.class_,
                  label: 'Manage Classes & Subjects',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ManageClassesScreen(currentUser: user)),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.enterMarks,
                  icon: Icons.edit_note,
                  label: 'Enter Marks',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class & Subject to Enter Marks',
                        onSelected: (classId, subjectId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => EnterMarksScreen(
                                currentUser: user,
                                classId: classId,
                                subjectId: subjectId,
                                term: currentTerm,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.viewAllAcademics,
                  icon: Icons.receipt_long,
                  label: 'Report Cards',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class for Report Cards',
                        onSelected: (classId, _) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ReportCardScreen(
                                currentUser: user,
                                classId: classId,
                                term: currentTerm,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.editSyllabusCoverage,
                  icon: Icons.checklist,
                  label: 'Syllabus Coverage',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class & Subject for Syllabus',
                        onSelected: (classId, subjectId) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SyllabusTrackerScreen(
                                currentUser: user,
                                classId: classId,
                                subjectId: subjectId,
                                term: currentTerm,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.triggerMidTermReport,
                  icon: Icons.analytics,
                  label: 'Mid-Term Pass/Fail Report',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SelectClassSubjectScreen(
                        currentUser: user,
                        title: 'Select Class for Mid-Term Report',
                        onSelected: (classId, _) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MidTermReportScreen(
                                currentUser: user,
                                classId: classId,
                                term: currentTerm,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.viewFinance,
                  icon: Icons.payments,
                  label: 'Fees & Defaulters',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FeeManagementScreen(currentUser: user, term: currentTerm),
                    ),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.viewPayroll,
                  icon: Icons.account_balance_wallet,
                  label: 'Payroll',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PayrollScreen(currentUser: user)),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.manageStaff,
                  icon: Icons.people,
                  label: 'Staff / HR',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => StaffManagementScreen(currentUser: user)),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.viewProcurement,
                  icon: Icons.inventory_2,
                  label: 'Procurement',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProcurementScreen(currentUser: user)),
                  ),
                ),
                RoleGatedAction(
                  role: user.role,
                  capability: Capability.checkInAttendance,
                  icon: Icons.login,
                  label: 'Teacher Check-In',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(currentUser: user)),
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