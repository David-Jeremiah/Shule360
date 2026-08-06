import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../permissions/role.dart';
import '../widgets/school_shell.dart';
import 'teacher_dashboard_screen.dart';
import 'hod_dashboard_screen.dart';
import 'parent_portal_screen.dart';
import 'platform_admin_dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;

  /// No longer used directly — SchoolScaffold streams the live School doc
  /// itself for logo/color, which is more accurate. Kept as an optional
  /// param so existing call sites passing it don't break.
  final String? schoolLogoUrl;

  const HomeScreen({super.key, required this.user, this.schoolLogoUrl});

  static const currentTerm = '2026-T2';

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.platformAdmin) {
      return const PlatformAdminDashboardScreen();
    }

    late final Widget dashboardBody;
    late final String pageTitle;

    switch (user.role) {
      case UserRole.parent:
        dashboardBody = ParentPortalScreen(currentUser: user, term: currentTerm);
        pageTitle = 'My Child';
        break;
      case UserRole.teacher:
      case UserRole.classTeacher:
        dashboardBody = TeacherDashboardScreen(user: user, term: currentTerm);
        pageTitle = 'Teacher Dashboard';
        break;
      case UserRole.hod:
        dashboardBody = HodDashboardScreen(user: user, term: currentTerm);
        pageTitle = 'Department Dashboard';
        break;
      default:
        dashboardBody = const _AdminHomeStats();
        pageTitle = 'Admin Dashboard';
    }

    return SchoolScaffold(
      currentUser: user,
      term: currentTerm,
      pageTitle: pageTitle,
      body: dashboardBody,
    );
  }
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

class _AdminHomeStats extends StatelessWidget {
  const _AdminHomeStats();

  static List<_StatCardData> _mockStats() {
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

  @override
  Widget build(BuildContext context) {
    return _StatGrid(stats: _mockStats());
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