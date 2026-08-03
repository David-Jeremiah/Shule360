import 'package:flutter/material.dart';
import '../models/school.dart';
import '../services/platform_admin_service.dart';
import 'add_school_screen.dart';
import 'platform_team_screen.dart';


class PlatformAdminDashboardScreen extends StatefulWidget {
  const PlatformAdminDashboardScreen({super.key});

  @override
  State<PlatformAdminDashboardScreen> createState() => _PlatformAdminDashboardScreenState();
}

class _PlatformAdminDashboardScreenState extends State<PlatformAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final service = PlatformAdminService();

    return Column(
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _StatCard(icon: Icons.check_circle, label: 'Active', value: '$active', color: Colors.green),
                  const SizedBox(width: 16),
                  _StatCard(icon: Icons.warning, label: 'Lapsed', value: '$lapsed', color: Colors.orange),
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
    );
  }
}

class _SchoolsListTab extends StatelessWidget {
  final PlatformAdminService service;
  const _SchoolsListTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<School>>(
      stream: service.watchAllSchools(),
      builder: (context, snapshot) {
        final schools = snapshot.data ?? [];
        if (schools.isEmpty) {
          return const Center(child: Text('No schools onboarded yet.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: schools.length,
          itemBuilder: (context, index) {
            final s = schools[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: s.isWithinGracePeriod
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      child: Icon(
                        s.isWithinGracePeriod ? Icons.check_circle : Icons.warning,
                        color: s.isWithinGracePeriod ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('${s.district} • ${s.level.name} • ${s.tier.name} tier • slug: ${s.slug}'),
                          if (s.contactPersonName != null)
                            Text(
                              'Contact: ${s.contactPersonName}${s.contactPersonPhone != null ? ' (${s.contactPersonPhone})' : ''}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AddSchoolScreen(existingSchool: s)),
                      ),
                    ),
                  ],
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