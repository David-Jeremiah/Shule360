import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_user.dart';
import '../models/school.dart';
import '../services/school_service.dart';
import '../widgets/sign_out_button.dart';

class SchoolSettingsScreen extends StatefulWidget {
  final AppUser currentUser;

  const SchoolSettingsScreen({super.key, required this.currentUser});

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

const _palette = <String>[
  '#1F4E5C', '#2E7D32', '#B71C1C', '#6A1B9A', '#E65100', '#00838F', '#4527A0', '#37474F',
];

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  final _service = SchoolService();
  String? _selectedColorHex;
  bool _isUploadingLogo = false;

  Future<void> _pickAndUploadLogo(School school) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final Uint8List bytes = file.bytes!;
    final ext = (file.extension ?? 'png').toLowerCase();

    setState(() => _isUploadingLogo = true);
    try {
      final url = await _service.uploadLogo(
        schoolId: widget.currentUser.schoolId,
        bytes: bytes,
        fileExtension: ext,
      );
      await _service.updateBranding(schoolId: widget.currentUser.schoolId, logoUrl: url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload logo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingLogo = false);
    }
  }

  Future<void> _selectColor(String hex) async {
    setState(() => _selectedColorHex = hex);
    await _service.updateBranding(schoolId: widget.currentUser.schoolId, primaryColorHex: hex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School Settings'), actions: const [SignOutButton()]),
      body: StreamBuilder<School>(
        stream: _service.watchSchool(widget.currentUser.schoolId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final school = snapshot.data!;
          final activeColorHex = _selectedColorHex ?? school.primaryColorHex;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(school.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('${school.district} • slug: ${school.slug}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 28),

                  _Section(
                    title: 'School Logo',
                    icon: Icons.image,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundImage: school.logoUrl != null ? NetworkImage(school.logoUrl!) : null,
                          child: school.logoUrl == null
                              ? Icon(Icons.school, size: 36, color: Theme.of(context).colorScheme.primary)
                              : null,
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Upload a square logo — appears on report cards and in the app.'),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _isUploadingLogo ? null : () => _pickAndUploadLogo(school),
                                icon: const Icon(Icons.upload),
                                label: Text(_isUploadingLogo ? 'Uploading...' : 'Upload Logo'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _Section(
                    title: 'Brand Color',
                    icon: Icons.palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Changes apply across the whole app immediately.'),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _palette.map((hex) {
                            final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                            final isSelected = activeColorHex.toUpperCase() == hex.toUpperCase();
                            return GestureDetector(
                              onTap: () => _selectColor(hex),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(color: Colors.black, width: 3)
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}