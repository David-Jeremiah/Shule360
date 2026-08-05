import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';
import '../services/school_service.dart';
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
import 'exam_card_screen.dart';
import 'announcements_screen.dart';
import 'parent_portal_screen.dart';
import 'teacher_dashboard_screen.dart';
import 'hod_dashboard_screen.dart';
import 'school_settings_screen.dart';
import 'manage_users_screen.dart';
import 'sports_screen.dart';
import 'platform_admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;
  final String? schoolLogoUrl;

  const HomeScreen({super.key, required this.user, this.schoolLogoUrl});

  static const currentTerm = '2026-T2';

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (user.role) {
      case UserRole.platformAdmin:
        body = const PlatformAdminDashboardScreen();
        break;
      case UserRole.parent:
        body = ParentPortalScreen(currentUser: user, term: currentTerm);
        break;
      case UserRole.teacher:
      case UserRole.classTeacher:
        body = TeacherDashboardScreen(user: user, term: currentTerm);
        break;
      case UserRole.hod:
        body = HodDashboardScreen(user: user, term: currentTerm);
        break;
      default:
        body = _AdminDashboard(user: user);
    }

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            if (schoolLogoUrl != null) ...[
              CircleAvatar(radius: 16, backgroundImage: NetworkImage(schoolLogoUrl!)),
              const SizedBox(width: 10),
            ],
            Text('Shule360 — ${user.role.displayName}'),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Sign Out', icon: const Icon(Icons.logout), onPressed: () => _signOut(context)),
        ],
      ),
      body: body,
    );
  }
}

class _DashboardItem {
  final Capability capability;
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  _DashboardItem({
    required this.capability,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

class _AdminDashboard extends StatelessWidget {
  final AppUser user;
  const _AdminDashboard({required this.user});

  @override
  Widget build(BuildContext context) {
    const currentTerm = HomeScreen.currentTerm;
    final scheme = Theme.of(context).colorScheme;

    final sections = <String, List<_DashboardItem>>{
      'Setup': [
        _DashboardItem(
          capability: Capability.manageSchoolBranding,
          icon: Icons.palette,
          label: 'School Settings',
          subtitle: 'Logo & brand color',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SchoolSettingsScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageUserAccounts,
          icon: Icons.admin_panel_settings,
          label: 'Manage Users',
          subtitle: 'Staff accounts & subjects',
          onTap: () async {
            final school = await SchoolService().fetchSchool(user.schoolId);
            if (context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageUsersScreen(currentUser: user, schoolSlug: school.slug),
                ),
              );
            }
          },
        ),
        _DashboardItem(
          capability: Capability.manageTimetable,
          icon: Icons.class_,
          label: 'Classes & Subjects',
          subtitle: 'Structure your school',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ManageClassesScreen(currentUser: user)),
          ),
        ),
      ],
      'Academics': [
        _DashboardItem(
          capability: Capability.manageOwnClassStudents,
          icon: Icons.person_add,
          label: 'Register Student',
          subtitle: 'Enroll new students',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RegisterStudentScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.enterMarks,
          icon: Icons.edit_note,
          label: 'Enter Marks',
          subtitle: 'Record student scores',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class & Subject',
                onSelected: (classId, subjectId) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EnterMarksScreen(
                        currentUser: user, classId: classId, subjectId: subjectId, term: currentTerm,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewAllAcademics,
          icon: Icons.receipt_long,
          label: 'Report Cards',
          subtitle: 'View & print results',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class',
                onSelected: (classId, _) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReportCardScreen(currentUser: user, classId: classId, term: currentTerm),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _DashboardItem(
          capability: Capability.editSyllabusCoverage,
          icon: Icons.checklist,
          label: 'Syllabus Coverage',
          subtitle: 'Track topics taught',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class & Subject',
                onSelected: (classId, subjectId) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SyllabusTrackerScreen(
                        currentUser: user, classId: classId, subjectId: subjectId, term: currentTerm,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _DashboardItem(
          capability: Capability.triggerMidTermReport,
          icon: Icons.analytics,
          label: 'Mid-Term Report',
          subtitle: 'Pass/fail rates',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class',
                onSelected: (classId, _) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MidTermReportScreen(currentUser: user, classId: classId, term: currentTerm),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
      'Finance & Operations': [
        _DashboardItem(
          capability: Capability.viewFinance,
          icon: Icons.payments,
          label: 'Fees & Defaulters',
          subtitle: 'Track payments',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => FeeManagementScreen(currentUser: user, term: currentTerm)),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewFinance,
          icon: Icons.badge,
          label: 'Exam Cards',
          subtitle: 'Issue exam cards',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class',
                onSelected: (classId, _) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExamCardScreen(currentUser: user, classId: classId, term: currentTerm),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewPayroll,
          icon: Icons.account_balance_wallet,
          label: 'Payroll',
          subtitle: 'Staff salaries',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PayrollScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageStaff,
          icon: Icons.people,
          label: 'Staff / HR',
          subtitle: 'Staff records',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StaffManagementScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewProcurement,
          icon: Icons.inventory_2,
          label: 'Procurement',
          subtitle: 'Purchases & supplies',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProcurementScreen(currentUser: user)),
          ),
        ),
      ],
      'Community': [
        _DashboardItem(
          capability: Capability.manageSports,
          icon: Icons.sports_soccer,
          label: 'Sports',
          subtitle: 'Events & results',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SportsScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageAnnouncements,
          icon: Icons.campaign,
          label: 'Announcements',
          subtitle: 'Notices & dates',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AnnouncementsScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.checkInAttendance,
          icon: Icons.login,
          label: 'Teacher Check-In',
          subtitle: 'Class attendance',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(currentUser: user)),
          ),
        ),
      ],
    };

    final visibleSections = {
      for (final entry in sections.entries)
        entry.key: entry.value.where((item) => Permissions.can(user.role, item.capability)).toList()
    }..removeWhere((_, items) => items.isEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome, ${user.fullName}', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Signed in as ${user.role.displayName}',
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          for (final entry in visibleSections.entries) ...[
            Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = (constraints.maxWidth / 220).floor().clamp(1, 4);
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.5,
                  children: entry.value.map((item) => _DashboardCard(item: item)).toList(),
                );
              },
            ),
            const SizedBox(height: 28),
          ],
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;
  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer.withOpacity(0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: scheme.primary),
              ),
              const Spacer(),
              Text(item.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}