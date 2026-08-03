import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/fee_record.dart';
import '../models/mark_record.dart';
import '../services/fee_service.dart';
import '../services/marks_service.dart';
import 'announcements_screen.dart';

class ParentPortalScreen extends StatelessWidget {
  final AppUser currentUser;
  final String term;

  const ParentPortalScreen({super.key, required this.currentUser, required this.term});

  @override
  Widget build(BuildContext context) {
    final marksService = MarksService();
    final feeService = FeeService();

    if (currentUser.childStudentIds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parent Portal')),
        body: const Center(child: Text('No children linked to this account yet.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Portal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final childId in currentUser.childStudentIds) ...[
            Text('Child: $childId', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Results', style: Theme.of(context).textTheme.titleMedium),
            StreamBuilder<List<MarkRecord>>(
              stream: marksService.watchMarksForStudent(
                schoolId: currentUser.schoolId,
                studentId: childId,
                term: term,
              ),
              builder: (context, snapshot) {
                final marks = snapshot.data ?? [];
                if (marks.isEmpty) return const Text('No marks published yet.');
                return Column(
                  children: marks
                      .map((m) => ListTile(
                    dense: true,
                    title: Text('Subject: ${m.subjectId}'),
                    trailing: Text('${m.percentage.toStringAsFixed(1)}%'),
                  ))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            Text('Fee Balance', style: Theme.of(context).textTheme.titleMedium),
            StreamBuilder<List<FeeRecord>>(
              stream: feeService.watchFeeRecords(schoolId: currentUser.schoolId, term: term),
              builder: (context, snapshot) {
                final records = (snapshot.data ?? []).where((r) => r.studentId == childId).toList();
                if (records.isEmpty) return const Text('No fee record yet.');
                final r = records.first;
                return Text('Paid ${r.amountPaid} / ${r.amountDue} — Balance: ${r.balance}');
              },
            ),
            const Divider(height: 32),
          ],
          FilledButton.icon(
            icon: const Icon(Icons.campaign),
            label: const Text('View Announcements'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AnnouncementsScreen(currentUser: currentUser)),
            ),
          ),
        ],
      ),
    );
  }
}