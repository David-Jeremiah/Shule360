import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/announcement.dart';
import '../models/app_user.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';
import '../services/announcement_service.dart';

class AnnouncementsScreen extends StatefulWidget {
  final AppUser currentUser;

  const AnnouncementsScreen({super.key, required this.currentUser});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final _service = AnnouncementService();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  DateTime? _eventDate;

  Future<void> _post() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty || message.isEmpty) return;

    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.post(Announcement(
      id: id,
      schoolId: widget.currentUser.schoolId,
      title: title,
      message: message,
      postedAt: DateTime.now(),
      postedByUserId: widget.currentUser.id,
      eventDate: _eventDate,
    ));
    _titleController.clear();
    _messageController.clear();
    setState(() => _eventDate = null);
  }

  Future<void> _pickEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final canPost = Permissions.can(widget.currentUser.role, Capability.manageAnnouncements);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements & Important Dates')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (canPost) ...[
              Text('Post Announcement', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickEventDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_eventDate == null
                        ? 'Attach a date (optional)'
                        : 'Date: ${_eventDate!.toLocal()}'.split(' ')[0]),
                  ),
                  const Spacer(),
                  FilledButton(onPressed: _post, child: const Text('Post')),
                ],
              ),
              const Divider(height: 32),
            ],
            Text('Feed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Announcement>>(
                stream: _service.watchAll(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) return const Text('No announcements yet.');
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final a = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(a.eventDate != null ? Icons.event : Icons.campaign),
                          title: Text(a.title),
                          subtitle: Text(a.message),
                          trailing: a.eventDate != null
                              ? Text('${a.eventDate!.toLocal()}'.split(' ')[0])
                              : null,
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