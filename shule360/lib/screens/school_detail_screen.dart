import 'package:flutter/material.dart';
import '../models/school.dart';
import '../models/app_user.dart';
import '../permissions/role.dart';
import '../services/platform_admin_service.dart';
import 'add_school_screen.dart';

class SchoolDetailScreen extends StatelessWidget {
  final School school;

  const SchoolDetailScreen({super.key, required this.school});

  Color get _brandColor {
    try {
      final hex = school.primaryColorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1F4E5C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = PlatformAdminService();
    final brand = _brandColor;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              backgroundColor: brand,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit School',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AddSchoolScreen(existingSchool: school)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 56, bottom: 16, right: 56),
                title: Text(
                  school.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brand, brand.withOpacity(0.75)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 56),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              backgroundImage: school.logoUrl != null ? NetworkImage(school.logoUrl!) : null,
                              child: school.logoUrl == null
                                  ? Text(
                                school.name.isNotEmpty ? school.name[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${school.district} • ${_levelLabel(school.level)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('slug: ${school.slug}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: brand,
                  child: const TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Staff'),
                      Tab(text: 'Students'),
                      Tab(text: 'Parents'),
                    ],
                  ),
                ),
              ),
            ),
          ],
          body: StreamBuilder<List<AppUser>>(
            stream: service.watchSchoolUsers(school.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = snapshot.data ?? [];
              final staff = users.where((u) => !_isStudentOrParent(u.role)).toList();
              final students = users.where((u) => u.role == UserRole.student).toList();
              final parents = users.where((u) => u.role == UserRole.parent).toList();

              return TabBarView(
                children: [
                  _OverviewTab(school: school, brand: brand, users: users, staff: staff, students: students, parents: parents),
                  _PeopleList(users: staff, emptyLabel: 'No staff enrolled yet.', brand: brand),
                  _PeopleList(users: students, emptyLabel: 'No students enrolled yet.', brand: brand),
                  _PeopleList(users: parents, emptyLabel: 'No parents enrolled yet.', brand: brand),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  bool _isStudentOrParent(UserRole r) => r == UserRole.student || r == UserRole.parent;

  String _levelLabel(SchoolLevel level) => switch (level) {
    SchoolLevel.primary => 'Primary',
    SchoolLevel.secondary => 'Secondary',
    SchoolLevel.both => 'Primary & Secondary',
  };
}

class _OverviewTab extends StatelessWidget {
  final School school;
  final Color brand;
  final List<AppUser> users;
  final List<AppUser> staff;
  final List<AppUser> students;
  final List<AppUser> parents;

  const _OverviewTab({
    required this.school,
    required this.brand,
    required this.users,
    required this.staff,
    required this.students,
    required this.parents,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilGraceEnds = school.subscriptionPaidUntil
        .add(Duration(days: school.gracePeriodDays))
        .difference(DateTime.now())
        .inDays;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Total People', value: '${users.length}', icon: Icons.groups, color: brand)),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Staff', value: '${staff.length}', icon: Icons.badge, color: Colors.indigo)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _StatTile(label: 'Students', value: '${students.length}', icon: Icons.school, color: Colors.teal)),
            const SizedBox(width: 12),
            Expanded(child: _StatTile(label: 'Parents', value: '${parents.length}', icon: Icons.family_restroom, color: Colors.deepOrange)),
          ],
        ),
        const SizedBox(height: 24),
        _SectionCard(
          title: 'Subscription',
          brand: brand,
          children: [
            _InfoRow(
              icon: school.isWithinGracePeriod ? Icons.check_circle : Icons.warning_amber_rounded,
              iconColor: school.isWithinGracePeriod ? Colors.green : Colors.red,
              label: school.isWithinGracePeriod ? 'Active' : 'Lapsed',
              value: school.isWithinGracePeriod
                  ? '$daysUntilGraceEnds day(s) left in grace period'
                  : 'Grace period ended ${-daysUntilGraceEnds} day(s) ago',
            ),
            _InfoRow(icon: Icons.workspace_premium, label: 'Tier', value: _tierLabel(school.tier)),
            _InfoRow(icon: Icons.event, label: 'Paid Until', value: _formatDate(school.subscriptionPaidUntil)),
            _InfoRow(icon: Icons.hourglass_bottom, label: 'Grace Period', value: '${school.gracePeriodDays} days'),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Contact',
          brand: brand,
          children: [
            _InfoRow(icon: Icons.person, label: 'Name', value: school.contactPersonName ?? '—'),
            _InfoRow(icon: Icons.phone, label: 'Phone', value: school.contactPersonPhone ?? '—'),
            _InfoRow(icon: Icons.email, label: 'Email', value: school.contactPersonEmail ?? '—'),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Details',
          brand: brand,
          children: [
            _InfoRow(icon: Icons.location_city, label: 'District', value: school.district),
            _InfoRow(icon: Icons.link, label: 'Slug', value: school.slug),
          ],
        ),
      ],
    );
  }

  String _tierLabel(SubscriptionTier tier) => switch (tier) {
    SubscriptionTier.starter => 'Starter',
    SubscriptionTier.standard => 'Standard',
    SubscriptionTier.full => 'Full',
  };

  String _formatDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color brand;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.brand, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: brand, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _InfoRow({required this.icon, this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor ?? Theme.of(context).colorScheme.outline),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _PeopleList extends StatelessWidget {
  final List<AppUser> users;
  final String emptyLabel;
  final Color brand;

  const _PeopleList({required this.users, required this.emptyLabel, required this.brand});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = users[index];
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: CircleAvatar(
              backgroundColor: brand.withOpacity(0.12),
              child: Text(
                u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                style: TextStyle(color: brand, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text([
              u.role.displayName,
              if (u.departmentName != null && u.departmentName!.isNotEmpty) u.departmentName!,
              if (u.subjectIds.isNotEmpty) '${u.subjectIds.length} subject(s)',
            ].join(' • ')),
          ),
        );
      },
    );
  }
}