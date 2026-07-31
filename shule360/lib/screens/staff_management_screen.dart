import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shule360/screens/staff_member.dart' hide StaffMember;
import '../models/app_user.dart';
import '../models/staff_member.dart';
import '../services/staff_service.dart';

class StaffManagementScreen extends StatefulWidget {
  final AppUser currentUser;

  const StaffManagementScreen({super.key, required this.currentUser});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _service = StaffService();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _phoneController = TextEditingController();

  Future<void> _addStaff() async {
    final name = _nameController.text.trim();
    final position = _positionController.text.trim();
    if (name.isEmpty || position.isEmpty) return;

    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.addStaff(StaffMember(
      id: id,
      schoolId: widget.currentUser.schoolId,
      fullName: name,
      position: position,
      phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      hiredOn: DateTime.now(),
    ));
    _nameController.clear();
    _positionController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff / HR')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Staff Member', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _positionController,
                    decoration: const InputDecoration(labelText: 'Position'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone (optional)'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addStaff, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<StaffMember>>(
                stream: _service.watchStaff(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final staff = snapshot.data ?? [];
                  if (staff.isEmpty) return const Text('No staff added yet.');
                  return ListView.builder(
                    itemCount: staff.length,
                    itemBuilder: (context, index) {
                      final s = staff[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.badge),
                          title: Text(s.fullName),
                          subtitle: Text('${s.position}${s.phoneNumber != null ? ' • ${s.phoneNumber}' : ''}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}