import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/app_user.dart';
import '../models/school.dart';
import '../services/school_service.dart';
import '../widgets/school_shell.dart';// adjust import path to wherever SchoolScaffold lives

/// A larger, non-exhaustive preset palette. Anything outside this list is
/// still reachable via the "Custom" swatch, which opens a hex/RGB picker —
/// so brand color is no longer limited to 8 fixed options.
const _palette = <String>[
  '#1F4E5C', '#2E7D32', '#B71C1C', '#6A1B9A', '#E65100', '#00838F', '#4527A0', '#37474F',
  '#0D47A1', '#1B5E20', '#880E4F', '#4E342E', '#F9A825', '#3E2723', '#004D40', '#263238',
  '#5D4037', '#AD1457', '#283593', '#00695C', '#BF360C', '#6D4C41', '#33691E', '#4A148C',
];

class SchoolSettingsScreen extends StatefulWidget {
  final AppUser currentUser;

  const SchoolSettingsScreen({super.key, required this.currentUser});

  @override
  State<SchoolSettingsScreen> createState() => _SchoolSettingsScreenState();
}

class _SchoolSettingsScreenState extends State<SchoolSettingsScreen> {
  final _service = SchoolService();
  String? _selectedColorHex;
  bool _isUploadingLogo = false;
  bool _isSavingInfo = false;

  // Text controllers for the editable "school info" fields. These are
  // initialized once from the first snapshot so the user's in-progress
  // edits aren't clobbered by every subsequent stream tick.
  bool _infoControllersReady = false;
  final _nameController = TextEditingController();
  final _mottoController = TextEditingController();
  final _visionController = TextEditingController();
  final _missionController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final List<TextEditingController> _phoneControllers = [];

  @override
  void dispose() {
    _nameController.dispose();
    _mottoController.dispose();
    _visionController.dispose();
    _missionController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    for (final c in _phoneControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initInfoControllers(School school) {
    if (_infoControllersReady) return;
    _nameController.text = school.name;
    _mottoController.text = school.motto ?? '';
    _visionController.text = school.vision ?? '';
    _missionController.text = school.mission ?? '';
    _addressController.text = school.address ?? '';
    _emailController.text = school.email ?? '';
    _websiteController.text = school.website ?? '';
    final phones = school.phoneNumbers ?? <String>[];
    _phoneControllers
      ..clear()
      ..addAll(
        (phones.isEmpty ? [''] : phones).map((p) => TextEditingController(text: p)),
      );
    _infoControllersReady = true;
  }

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

  Future<void> _openCustomColorPicker(String initialHex) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _CustomColorDialog(initialHex: initialHex),
    );
    if (result != null) {
      await _selectColor(result);
    }
  }

  Future<void> _saveSchoolInfo() async {
    setState(() => _isSavingInfo = true);
    try {
      final phones = _phoneControllers
          .map((c) => c.text.trim())
          .where((p) => p.isNotEmpty)
          .toList();

      await _service.updateSchoolInfo(
        schoolId: widget.currentUser.schoolId,
        name: _nameController.text.trim(),
        motto: _mottoController.text.trim(),
        vision: _visionController.text.trim(),
        mission: _missionController.text.trim(),
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        phoneNumbers: phones,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School information saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingInfo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<School>(
      stream: _service.watchSchool(widget.currentUser.schoolId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // Still route through the shell so the sidebar/topbar don't pop
          // in only after the first snapshot arrives.
          return SchoolScaffold(
            currentUser: widget.currentUser,
            pageTitle: 'School Settings',
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final school = snapshot.data!;
        _initInfoControllers(school);
        final activeColorHex = _selectedColorHex ?? school.primaryColorHex;

        return SchoolScaffold(
          currentUser: widget.currentUser,
          pageTitle: 'School Settings',
          body: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${school.district} • slug: ${school.slug}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 20),

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
                        children: [
                          ..._palette.map((hex) {
                            final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                            final isSelected = activeColorHex.toUpperCase() == hex.toUpperCase();
                            return GestureDetector(
                              onTap: () => _selectColor(hex),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                              ),
                            );
                          }),
                          // Custom swatch — opens a full hex/RGB picker so
                          // brand color isn't limited to the preset list.
                          GestureDetector(
                            onTap: () => _openCustomColorPicker(activeColorHex),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.grey.shade400, width: 1.5),
                                gradient: const SweepGradient(
                                  colors: [
                                    Colors.red, Colors.yellow, Colors.green,
                                    Colors.cyan, Colors.blue, Colors.purple, Colors.red,
                                  ],
                                ),
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _Section(
                  title: 'School Information',
                  icon: Icons.info_outline,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'School Name'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _mottoController,
                        decoration: const InputDecoration(labelText: 'Motto'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _visionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Vision'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _missionController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Mission'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _Section(
                  title: 'Contact & Location',
                  icon: Icons.contact_mail_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Location / Address',
                          hintText: 'Street, town, district',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Contact Email'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(labelText: 'Website'),
                      ),
                      const SizedBox(height: 14),
                      Text('Phone Numbers', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      for (int i = 0; i < _phoneControllers.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneControllers[i],
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(labelText: 'Phone ${i + 1}'),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _phoneControllers.length == 1
                                    ? null
                                    : () => setState(() {
                                  final c = _phoneControllers.removeAt(i);
                                  c.dispose();
                                }),
                              ),
                            ],
                          ),
                        ),
                      TextButton.icon(
                        onPressed: () => setState(() => _phoneControllers.add(TextEditingController())),
                        icon: const Icon(Icons.add),
                        label: const Text('Add another number'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isSavingInfo ? null : _saveSchoolInfo,
                    icon: const Icon(Icons.save),
                    label: Text(_isSavingInfo ? 'Saving...' : 'Save Changes'),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CustomColorDialog extends StatefulWidget {
  final String initialHex;
  const _CustomColorDialog({required this.initialHex});

  @override
  State<_CustomColorDialog> createState() => _CustomColorDialogState();
}

class _CustomColorDialogState extends State<_CustomColorDialog> {
  late int _r, _g, _b;
  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    final clean = widget.initialHex.replaceAll('#', '');
    final value = int.tryParse('FF$clean', radix: 16) ?? 0xFF1F4E5C;
    final color = Color(value);
    _r = color.red;
    _g = color.green;
    _b = color.blue;
    _hexController = TextEditingController(text: '#$clean'.toUpperCase());
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  Color get _currentColor => Color.fromARGB(255, _r, _g, _b);

  void _syncFromRgb() {
    final hex = '#${_r.toRadixString(16).padLeft(2, '0')}'
        '${_g.toRadixString(16).padLeft(2, '0')}'
        '${_b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
    _hexController.text = hex;
  }

  void _syncFromHex(String value) {
    final clean = value.replaceAll('#', '').trim();
    if (clean.length != 6) return;
    final parsed = int.tryParse('FF$clean', radix: 16);
    if (parsed == null) return;
    final color = Color(parsed);
    setState(() {
      _r = color.red;
      _g = color.green;
      _b = color.blue;
    });
  }

  Widget _slider(String label, int value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 16, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 32, child: Text('$value')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom Brand Color'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(labelText: 'Hex', prefixText: ''),
              onChanged: _syncFromHex,
            ),
            const SizedBox(height: 8),
            _slider('R', _r, (v) => setState(() { _r = v.round(); _syncFromRgb(); })),
            _slider('G', _g, (v) => setState(() { _g = v.round(); _syncFromRgb(); })),
            _slider('B', _b, (v) => setState(() { _b = v.round(); _syncFromRgb(); })),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_hexController.text),
          child: const Text('Apply'),
        ),
      ],
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