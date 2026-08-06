import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';
import '../services/school_service.dart';
import '../screens/register_student_screen.dart';
import '../screens/manage_classes_screen.dart';
import '../screens/select_class_subject_screen.dart';
import '../screens/select_my_class_screen.dart';
import '../screens/enter_marks_screen.dart';
import '../screens/fee_management_screen.dart';
import '../screens/teacher_attendance_screen.dart';
import '../screens/syllabus_tracker_screen.dart';
import '../screens/mid_term_report_screen.dart';
import '../screens/payroll_screen.dart';
import '../screens/procurement_screen.dart';
import '../screens/report_card_screen.dart';
import '../screens/staff_management_screen.dart';
import '../screens/exam_card_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/school_settings_screen.dart';
import '../screens/manage_users_screen.dart';
import '../screens/sports_screen.dart';
import '../screens/assign_class_teacher_screen.dart';
import '../screens/manage_timetable_screen.dart';

/// Below this width we switch from a persistent sidebar to a Drawer.
const kMobileBreakpoint = 700.0;

Color colorFromHex(String? hex, {Color fallback = const Color(0xFF12369B)}) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return fallback;
  }
}

class _DashboardItem {
  final Capability capability;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _DashboardItem({
    required this.capability,
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class _NavSection {
  final String title;
  final List<_DashboardItem> items;
  _NavSection({required this.title, required this.items});
}

/// The shared shell every school-facing dashboard page renders inside:
/// sidebar nav (capability-filtered, so it auto-adapts to whatever role
/// is logged in, with the school logo in its header) + top bar (school
/// name, then search below it) + whatever [body] the caller supplies for
/// the main content area.
///
/// This does NOT wrap most screens pushed via Navigator.push elsewhere
/// (Manage Classes, Payroll, etc.) — those keep their own plain AppBar.
/// School Settings is the exception: it wraps itself in this shell too.
class SchoolScaffold extends StatefulWidget {
  final AppUser currentUser;
  final String pageTitle;
  final String? breadcrumb;
  final Widget body;
  final String term;

  const SchoolScaffold({
    super.key,
    required this.currentUser,
    required this.pageTitle,
    required this.body,
    this.breadcrumb,
    this.term = '2026-T2',
  });

  @override
  State<SchoolScaffold> createState() => _SchoolScaffoldState();
}

class _SchoolScaffoldState extends State<SchoolScaffold> {
  String? _selectedLabel;
  bool _sidebarExpanded = true;
  final _schoolService = SchoolService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _defaultSidebarBg = Color(0xFF12369B);

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final sections = _buildSections(context, user, widget.term);

    return StreamBuilder<School>(
      stream: _schoolService.watchSchool(user.schoolId),
      builder: (context, schoolSnapshot) {
        final school = schoolSnapshot.data;
        final brandColor = colorFromHex(school?.primaryColorHex, fallback: _defaultSidebarBg);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < kMobileBreakpoint;

            final sidebar = _Sidebar(
              expanded: isMobile ? true : _sidebarExpanded,
              onToggle: isMobile ? null : () => setState(() => _sidebarExpanded = !_sidebarExpanded),
              sections: sections,
              selectedLabel: _selectedLabel,
              bg: brandColor,
              schoolName: school?.name ?? 'Shule360',
              schoolLogoUrl: school?.logoUrl,
              onSelect: (label) {
                setState(() => _selectedLabel = label);
                if (isMobile) Navigator.of(context).maybePop(); // closes the Drawer
              },
            );

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: const Color(0xFFF4F6FB),
              drawer: isMobile ? Drawer(child: sidebar) : null,
              body: Row(
                children: [
                  if (!isMobile) sidebar,
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          user: user,
                          schoolName: school?.name ?? 'Shule360',
                          brandColor: brandColor,
                          onSignOut: () => _signOut(context),
                          onMenuTap: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.pageTitle,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: brandColor,
                                    )),
                                const SizedBox(height: 4),
                                Text(widget.breadcrumb ?? 'Dashboard / ${widget.pageTitle}',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 24),
                                widget.body,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<_NavSection> _buildSections(BuildContext context, AppUser user, String currentTerm) {
    final raw = <String, List<_DashboardItem>>{
      '': [
        _DashboardItem(
          capability: Capability.manageOwnClassStudents,
          icon: Icons.groups,
          label: 'Learners',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => RegisterStudentScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageStaff,
          icon: Icons.badge,
          label: 'Staff',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => StaffManagementScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageUserAccounts,
          icon: Icons.people_alt,
          label: 'Users',
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
      ],
      'SETUP': [
        _DashboardItem(
          capability: Capability.manageSchoolBranding,
          icon: Icons.palette,
          label: 'School Settings',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SchoolSettingsScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageTimetable,
          icon: Icons.class_,
          label: 'Classes & Subjects',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ManageClassesScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageTimetable,
          icon: Icons.assignment_ind,
          label: 'Assign Class Teacher',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AssignClassTeacherScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageTimetable,
          icon: Icons.schedule,
          label: 'Timetable',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ManageTimetableScreen(currentUser: user)),
          ),
        ),
      ],
      'FINANCE': [
        _DashboardItem(
          capability: Capability.viewFinance,
          icon: Icons.payments,
          label: 'Fees & Defaulters',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => FeeManagementScreen(currentUser: user, term: currentTerm)),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewFinance,
          icon: Icons.badge_outlined,
          label: 'Exam Cards',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ExamCardScreen(currentUser: user, term: currentTerm),
            ),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewPayroll,
          icon: Icons.account_balance_wallet,
          label: 'Payroll',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PayrollScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.viewProcurement,
          icon: Icons.inventory_2,
          label: 'Procurement',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ProcurementScreen(currentUser: user)),
          ),
        ),
      ],
      'ACADEMICS': [
        _DashboardItem(
          capability: Capability.enterMarks,
          icon: Icons.edit_note,
          label: 'Enter Marks',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class & Subject',
                departmentFilter: user.role == UserRole.hod ? user.departmentName : null,
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassScreen(
                currentUser: user,
                title: 'Select Class',
                onSelected: (classId) {
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassSubjectScreen(
                currentUser: user,
                title: 'Select Class & Subject',
                departmentFilter: user.role == UserRole.hod ? user.departmentName : null,
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SelectClassScreen(
                currentUser: user,
                title: 'Select Class',
                onSelected: (classId) {
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
      'COMMUNITY': [
        _DashboardItem(
          capability: Capability.manageSports,
          icon: Icons.sports_soccer,
          label: 'Sports',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SportsScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.manageAnnouncements,
          icon: Icons.campaign,
          label: 'Announcements',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AnnouncementsScreen(currentUser: user)),
          ),
        ),
        _DashboardItem(
          capability: Capability.checkInAttendance,
          icon: Icons.login,
          label: 'Teacher Check-In',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TeacherAttendanceScreen(currentUser: user)),
          ),
        ),
      ],
    };

    return raw.entries
        .map((e) => _NavSection(
      title: e.key,
      items: e.value.where((item) => Permissions.can(user.role, item.capability)).toList(),
    ))
        .where((s) => s.items.isNotEmpty)
        .toList();
  }
}

class _Sidebar extends StatelessWidget {
  final bool expanded;
  final VoidCallback? onToggle;
  final List<_NavSection> sections;
  final String? selectedLabel;
  final ValueChanged<String> onSelect;
  final Color bg;
  final String schoolName;
  final String? schoolLogoUrl;

  const _Sidebar({
    required this.expanded,
    required this.onToggle,
    required this.sections,
    required this.selectedLabel,
    required this.onSelect,
    required this.bg,
    required this.schoolName,
    this.schoolLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: onToggle == null ? null : (expanded ? 260 : 76),
      color: bg,
      child: SafeArea(
        child: Column(
          children: [
            // Collapse toggle, top-right.
            SizedBox(
              height: 44,
              child: onToggle != null
                  ? Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(expanded ? Icons.chevron_left : Icons.chevron_right, color: Colors.white70),
                    onPressed: onToggle,
                  ),
                ),
              )
                  : null,
            ),
            // School logo header.
            Padding(
              padding: EdgeInsets.symmetric(vertical: expanded ? 12 : 8, horizontal: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: expanded ? 34 : 20,
                    backgroundColor: Colors.white,
                    backgroundImage: schoolLogoUrl != null ? NetworkImage(schoolLogoUrl!) : null,
                    child: schoolLogoUrl == null
                        ? Icon(Icons.school, color: bg, size: expanded ? 34 : 20)
                        : null,
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 10),
                    Text(
                      schoolName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final section in sections) ...[
                    if (section.title.isNotEmpty && expanded)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                        child: Text(
                          section.title,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    for (final item in section.items)
                      _SidebarTile(
                        icon: item.icon,
                        label: item.label,
                        expanded: expanded,
                        selected: selectedLabel == item.label,
                        onTap: () {
                          onSelect(item.label);
                          item.onTap();
                        },
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool expanded;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                if (expanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Top bar now carries just the school name (bigger, since the logo
/// lives in the sidebar header) plus the icon cluster, with the search
/// field on its own row directly beneath.
class _TopBar extends StatelessWidget {
  final AppUser user;
  final String schoolName;
  final Color brandColor;
  final VoidCallback onSignOut;
  final VoidCallback? onMenuTap;

  const _TopBar({
    required this.user,
    required this.schoolName,
    required this.brandColor,
    required this.onSignOut,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onMenuTap != null) ...[
                IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap, padding: EdgeInsets.zero),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  schoolName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () {}),
              Stack(
                children: [
                  IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'signout') onSignOut();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'signout', child: Text('Sign Out')),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 18)),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF4F6FB),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}