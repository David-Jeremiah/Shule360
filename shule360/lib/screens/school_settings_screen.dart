import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/school.dart';
import '../services/school_service.dart';

class SchoolSettingsScreen extends StatefulWidget {
  final AppUser currentUser;

  const SchoolSettingsScreen({super.key, required this.currentUser});

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  final _service = SchoolService();
  final _logoUrlController = TextEditingController();
  final _colorController = TextEditingController();
  bool _loaded = false;

  Future<void> _save() async {
    await _service.updateBranding(
      schoolId: widget.currentUser.schoolId,
      logoUrl: _logoUrlController.text.trim(),
      primaryColorHex: _colorController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Branding updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('School Settings')),
      body: StreamBuilder<School>(
        stream: _service.watchSchool(widget.currentUser.schoolId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final school = snapshot.data!;
          if (!_loaded) {
            _logoUrlController.text = school.logoUrl ?? '';
            _colorController.text = school.primaryColorHex;
            _loaded = true;
          }
          return Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('School: ${school.name}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _logoUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Logo URL',
                      hintText: 'https://...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _colorController,
                    decoration: const InputDecoration(
                      labelText: 'Primary color (hex)',
                      hintText: '#1F4E5C',
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: _save, child: const Text('Save Branding')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}