import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/school.dart';
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
import 'assign_class_teacher_screen.dart';

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
    if (user.role == UserRole.platformAdmin) {
      return const PlatformAdminDashboardScreen();
    }
    if (user.role != UserRole.parent &&
        user.role != UserRole.teacher &&
        user.role != UserRole.classTeacher &&
        user.role != UserRole.hod &&
        !_isBasicRole(user.role)) {
      return _AdminDashboard(user: user, onSignOut: () => _signOut(context));
    }

    Widget body;
    switch (user.role) {
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
        body = _AdminDashboard(user: user, onSignOut: () => _signOut(context));
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
            Flexible(child: Text('Shule360 — ${user.role.displayName}', overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(tooltip: 'Sign Out', icon: const Icon(Icons.logout), onPressed: () => _signOut(context)),
        ],
      ),
      body: body,
    );
  }

  bool _isBasicRole(UserRole role) => false;
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

class _StatCardData {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final List<_SubStat> subStats;

  _StatCardData({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.subStats = const [],
  });
}

class _SubStat {
  final String label;
  final String value;
  const _SubStat(this.label, this.value);
}

class _NavSection {
  final String title;
  final List<_DashboardItem> items;
  _NavSection({required this.title, required this.items});
}

class _AdminDashboard extends StatefulWidget {
  final AppUser user;
  final VoidCallback onSignOut;
  const _AdminDashboard({required this.user, required this.onSignOut});

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  String _selectedLabel = 'Admin Dashboard';
  bool _sidebarExpanded = true;
  final _schoolService = SchoolService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _defaultSidebarBg = Color(0xFF12369B);

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    const currentTerm = HomeScreen.currentTerm;
    final sections = _buildSections(context, user, currentTerm);

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
              onSelect: (label) {
                setState(() => _selectedLabel = label);
                if (isMobile) Navigator.of(context).maybePop(); // closes the Drawer
              },
              bg: brandColor,
              schoolName: school?.name ?? 'Shule360',
              schoolLogoUrl: school?.logoUrl,
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
                          onSignOut: widget.onSignOut,
                          onMenuTap: isMobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Admin Dashboard',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: brandColor,
                                    )),
                                const SizedBox(height: 4),
                                Text('Dashboard / Admin Dashboard',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                const SizedBox(height: 24),
                                _StatGrid(stats: _mockStats()),
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

  List<_StatCardData> _mockStats() {
    return [
      _StatCardData(icon: Icons.school, color: const Color(0xFFE05263), value: '1,200', label: 'Total Learners',
          subStats: const [_SubStat('Male', '594'), _SubStat('Female', '606')]),
      _StatCardData(icon: Icons.request_quote, color: const Color(0xFF8E5BE0), value: '65,091,369', label: 'Expected Fees',
          subStats: const [_SubStat('Invoiced', '1,620,400'), _SubStat('Discounts', '2,400,000')]),
      _StatCardData(icon: Icons.volunteer_activism, color: const Color(0xFF8E5BE0), value: '1,535,150,000', label: 'Collected Amount',
          subStats: const [_SubStat('From Expected', '600,000'), _SubStat('Prepaid/Excess', '1,534,550')]),
      _StatCardData(icon: Icons.trending_up, color: const Color(0xFF2FA84F), value: '1,535,150,000', label: 'Other Revenues',
          subStats: const [_SubStat('0% Fees', '600,000')]),
      _StatCardData(icon: Icons.favorite, color: const Color(0xFF17B6B0), value: '1,535,150,000', label: 'Total Bursaries',
          subStats: const [_SubStat('Bursaries % to Fees', '600,000')]),
      _StatCardData(icon: Icons.local_offer, color: const Color(0xFFEB9B34), value: '1,535,150,000', label: 'Total Exemptions',
          subStats: const [_SubStat('Exemptions % to Fees', '600,000')]),
      _StatCardData(icon: Icons.point_of_sale, color: const Color(0xFFE0435B), value: '1,535,150,000', label: 'Total Expenses',
          subStats: const [_SubStat('Expenses % to Revenue', '600,000')]),
      _StatCardData(icon: Icons.groups_2, color: const Color(0xFF3C4CB8), value: '25', label: 'Staff Members',
          subStats: const [_SubStat('Enrolled Users', '31'), _SubStat('Ordinary Staff', '-6')]),
    ];
  }
}

class _Sidebar extends StatelessWidget {
  final bool expanded;
  final VoidCallback? onToggle; // null on mobile (Drawer has no collapse toggle)
  final List<_NavSection> sections;
  final String selectedLabel;
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
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    backgroundImage: schoolLogoUrl != null ? NetworkImage(schoolLogoUrl!) : null,
                    child: schoolLogoUrl == null ? Icon(Icons.school, color: bg, size: 18) : null,
                  ),
                  if (expanded) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        schoolName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (onToggle != null)
                    IconButton(
                      icon: Icon(expanded ? Icons.chevron_left : Icons.chevron_right, color: Colors.white70),
                      onPressed: onToggle,
                    ),
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
        color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
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

class _TopBar extends StatelessWidget {
  final AppUser user;
  final VoidCallback onSignOut;
  final VoidCallback? onMenuTap; // set on mobile to open the Drawer
  const _TopBar({required this.user, required this.onSignOut, this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (onMenuTap != null) ...[
            IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
          ),
          const SizedBox(width: 8),
          if (onMenuTap == null) ...[
            IconButton(icon: const Icon(Icons.dark_mode_outlined), onPressed: () {}),
            IconButton(icon: const Icon(Icons.fullscreen), onPressed: () {}),
          ],
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
                if (onMenuTap == null) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text(user.role.displayName,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(Icons.expand_more, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<_StatCardData> stats;
  const _StatGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 260).floor().clamp(1, 4);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.2 : 1.35,
          ),
          itemBuilder: (context, i) => _StatCard(data: stats[i]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: data.color, borderRadius: BorderRadius.circular(10)),
                child: Icon(data.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    Text(data.label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (data.subStats.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(color: const Color(0xFFF4F6FB), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  for (final sub in data.subStats)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sub.label,
                                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(sub.value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
  }
}