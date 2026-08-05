import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/school.dart';
import '../services/platform_admin_service.dart';
import 'add_school_screen.dart';
import 'platform_team_screen.dart';
import 'school_detail_screen.dart';

class PlatformAdminDashboardScreen extends StatefulWidget {
  const PlatformAdminDashboardScreen({super.key});

  @override
  State<PlatformAdminDashboardScreen> createState() => _PlatformAdminDashboardScreenState();
}

class _PlatformAdminDashboardScreenState extends State<PlatformAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _bg = Color(0xFFF7F8FC);
  static const _surface = Colors.white;
  static const _accent = Color(0xFF3B5BDB);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    final service = PlatformAdminService();

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bg,
        colorScheme: ColorScheme.light(
          primary: _accent,
          surface: _surface,
          onSurface: Colors.black87,
          outline: const Color(0xFFE2E4EC),
        ),
        cardColor: _surface,
        tabBarTheme: TabBarThemeData(
          labelColor: _accent,
          unselectedLabelColor: _textSecondary,
          indicatorColor: _accent,
        ),
      ),
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _surface,
          foregroundColor: Colors.black87,
          elevation: 0,
          scrolledUnderElevation: 1,
          title: const Text('Platform Admin'),
          actions: [
            IconButton(
              tooltip: 'Sign Out',
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: StreamBuilder<List<School>>(
                stream: service.watchAllSchools(),
                builder: (context, snapshot) {
                  final schools = snapshot.data ?? [];
                  final active = schools.where((s) => s.isWithinGracePeriod).length;
                  final lapsed = schools.length - active;
                  return Row(
                    children: [
                      _StatCard(
                        icon: Icons.school,
                        label: 'Total Schools',
                        value: '${schools.length}',
                        color: _accent,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.check_circle,
                        label: 'Active',
                        value: '$active',
                        color: const Color(0xFF2FA84F),
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        icon: Icons.warning,
                        label: 'Lapsed',
                        value: '$lapsed',
                        color: const Color(0xFFE0A83C),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Schools', icon: Icon(Icons.list)),
                Tab(text: 'Add School', icon: Icon(Icons.add_business)),
                Tab(text: 'Platform Team', icon: Icon(Icons.shield)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SchoolsListTab(service: service),
                  const AddSchoolScreen(),
                  const PlatformTeamScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolsListTab extends StatelessWidget {
  final PlatformAdminService service;
  const _SchoolsListTab({required this.service});

  Color _brandColorFor(School s) {
    try {
      final hex = s.primaryColorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1F4E5C);
    }
  }

  String _tierLabel(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.starter => 'Starter',
    SubscriptionTier.standard => 'Standard',
    SubscriptionTier.full => 'Full',
  };

  String _levelLabel(SchoolLevel level) => switch (level) {
    SchoolLevel.primary => 'Primary',
    SchoolLevel.secondary => 'Secondary',
    SchoolLevel.both => 'Primary & Secondary',
  };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<School>>(
      stream: service.watchAllSchools(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final schools = snapshot.data ?? [];
        if (schools.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 12),
                const Text('No schools onboarded yet.'),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: schools.length,
          itemBuilder: (context, index) {
            final s = schools[index];
            final brand = _brandColorFor(s);
            final statusColor = s.isWithinGracePeriod ? Colors.green : Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => SchoolDetailScreen(school: s)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: brand.withOpacity(0.12),
                        backgroundImage: s.logoUrl != null ? NetworkImage(s.logoUrl!) : null,
                        child: s.logoUrl == null
                            ? Text(
                          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                          style: TextStyle(color: brand, fontWeight: FontWeight.bold, fontSize: 18),
                        )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        s.isWithinGracePeriod ? Icons.check_circle : Icons.warning_amber_rounded,
                                        size: 12,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        s.isWithinGracePeriod ? 'Active' : 'Lapsed',
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${s.district} • ${_levelLabel(s.level)} • ${_tierLabel(s.tier)} tier',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              'slug: ${s.slug}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            if (s.contactPersonName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Contact: ${s.contactPersonName}${s.contactPersonPhone != null ? ' (${s.contactPersonPhone})' : ''}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit School',
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => AddSchoolScreen(existingSchool: s)),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}