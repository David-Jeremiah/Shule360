import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/sports_event.dart';
import '../services/sports_service.dart';

class SportsScreen extends StatefulWidget {
  final AppUser currentUser;

  const SportsScreen({super.key, required this.currentUser});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  final _service = SportsService();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  DateTime _eventDate = DateTime.now();

  Future<void> _addEvent() async {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    if (name.isEmpty || category.isEmpty) return;

    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.addEvent(SportsEvent(
      id: id,
      schoolId: widget.currentUser.schoolId,
      name: name,
      category: category,
      eventDate: _eventDate,
    ));
    _nameController.clear();
    _categoryController.clear();
  }

  Future<void> _recordResult(SportsEvent event) async {
    final controller = TextEditingController(text: event.resultSummary ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Result — ${event.name}'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Result summary')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await _service.updateResult(widget.currentUser.schoolId, event.id, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sports')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Event name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addEvent, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<SportsEvent>>(
                stream: _service.watchAll(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final events = snapshot.data ?? [];
                  if (events.isEmpty) return const Text('No sports events yet.');
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final e = events[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.sports_soccer),
                          title: Text('${e.name} (${e.category})'),
                          subtitle: Text(e.resultSummary ?? 'No result yet'),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _recordResult(e),
                          ),
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