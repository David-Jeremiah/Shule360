import 'package:flutter/material.dart';
import '../models/school.dart';
import '../permissions/role.dart';
import '../services/platform_admin_service.dart';
import '../services/user_admin_service.dart';
import '../widgets/sign_out_button.dart';

class AddSchoolScreen extends StatefulWidget {
  final School? existingSchool; // pass this to edit instead of create

  const AddSchoolScreen({super.key, this.existingSchool});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PlatformAdminService();
  final _userService = UserAdminService();

  late final _nameController = TextEditingController(text: widget.existingSchool?.name ?? '');
  late final _slugController = TextEditingController(text: widget.existingSchool?.slug ?? '');
  late final _districtController = TextEditingController(text: widget.existingSchool?.district ?? '');
  late final _contactNameController =
  TextEditingController(text: widget.existingSchool?.contactPersonName ?? '');
  late final _contactPhoneController =
  TextEditingController(text: widget.existingSchool?.contactPersonPhone ?? '');
  late final _contactEmailController =
  TextEditingController(text: widget.existingSchool?.contactPersonEmail ?? '');
  final _adminPasswordController = TextEditingController();
  late SchoolLevel _level = widget.existingSchool?.level ?? SchoolLevel.both;
  late SubscriptionTier _tier = widget.existingSchool?.tier ?? SubscriptionTier.starter;
  bool _createAdminAccount = false;
  bool _isSaving = false;

  bool get _isEditMode => widget.existingSchool != null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      if (_isEditMode) {
        final updated = School(
          id: widget.existingSchool!.id,
          name: _nameController.text.trim(),
          slug: _slugController.text.trim(),
          district: _districtController.text.trim(),
          level: _level,
          tier: _tier,
          subscriptionPaidUntil: widget.existingSchool!.subscriptionPaidUntil,
          gracePeriodDays: widget.existingSchool!.gracePeriodDays,
          logoUrl: widget.existingSchool!.logoUrl,
          primaryColorHex: widget.existingSchool!.primaryColorHex,
          contactPersonName: _contactNameController.text.trim(),
          contactPersonPhone: _contactPhoneController.text.trim(),
          contactPersonEmail: _contactEmailController.text.trim().isEmpty
              ? null
              : _contactEmailController.text.trim(),
        );
        await _service.updateSchool(updated);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${updated.name} updated')),
        );
        Navigator.of(context).pop();
        return;
      }

      final school = School(
        id: '',
        name: _nameController.text.trim(),
        slug: _slugController.text.trim(),
        district: _districtController.text.trim(),
        level: _level,
        tier: _tier,
        subscriptionPaidUntil: DateTime.now().add(const Duration(days: 90)),
        contactPersonName: _contactNameController.text.trim(),
        contactPersonPhone: _contactPhoneController.text.trim(),
        contactPersonEmail: _contactEmailController.text.trim().isEmpty
            ? null
            : _contactEmailController.text.trim(),
      );
      final schoolId = await _service.createSchool(school);

      if (_createAdminAccount) {
        final email = 'admin@${school.slug}.shule360';
        await _userService.createStaffAccount(
          email: email,
          password: _adminPasswordController.text,
          fullName: _contactNameController.text.trim(),
          schoolId: schoolId,
          role: UserRole.schoolAdmin,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${school.name} onboarded successfully')),
      );
      _formKey.currentState!.reset();
      _nameController.clear();
      _slugController.clear();
      _districtController.clear();
      _contactNameController.clear();
      _contactPhoneController.clear();
      _contactEmailController.clear();
      _adminPasswordController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save school: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'School Details',
                icon: Icons.school,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'School name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _slugController,
                    decoration: const InputDecoration(
                      labelText: 'Slug (used for email domain)',
                      hintText: 'stamayass',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _districtController,
                    decoration: const InputDecoration(labelText: 'District'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<SchoolLevel>(
                    initialValue: _level,
                    decoration: const InputDecoration(labelText: 'School level'),
                    items: const [
                      DropdownMenuItem(value: SchoolLevel.primary, child: Text('Primary only')),
                      DropdownMenuItem(value: SchoolLevel.secondary, child: Text('Secondary only')),
                      DropdownMenuItem(value: SchoolLevel.both, child: Text('Primary & Secondary')),
                    ],
                    onChanged: (l) => setState(() => _level = l ?? SchoolLevel.both),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<SubscriptionTier>(
                    initialValue: _tier,
                    decoration: const InputDecoration(labelText: 'Subscription tier'),
                    items: SubscriptionTier.values
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                        .toList(),
                    onChanged: (t) => setState(() => _tier = t ?? SubscriptionTier.starter),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SectionCard(
                title: 'Contact Person',
                icon: Icons.person,
                children: [
                  TextFormField(
                    controller: _contactNameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactPhoneController,
                    decoration: const InputDecoration(labelText: 'Phone number'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactEmailController,
                    decoration: const InputDecoration(labelText: 'Personal email (optional)'),
                  ),
                ],
              ),
              if (!_isEditMode) ...[
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'School Admin Account',
                  icon: Icons.admin_panel_settings,
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Create login account for contact person'),
                      subtitle: Text(_slugController.text.trim().isEmpty
                          ? 'admin@<slug>.shule360'
                          : 'admin@${_slugController.text.trim()}.shule360'),
                      value: _createAdminAccount,
                      onChanged: (v) => setState(() => _createAdminAccount = v),
                    ),
                    if (_createAdminAccount) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _adminPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Temporary password'),
                        validator: (v) => _createAdminAccount && (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _submit,
                  icon: Icon(_isEditMode ? Icons.save : Icons.add_business),
                  label: Text(_isSaving
                      ? 'Saving...'
                      : (_isEditMode ? 'Save Changes' : 'Onboard School')),
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!_isEditMode) return form; // embedded as a tab inside the dashboard, no its own Scaffold

    return Scaffold(
      appBar: AppBar(title: const Text('Edit School'), actions: const [SignOutButton()]),
      body: form,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.icon, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}