import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../models/syllabus_topic.dart';
import '../services/syllabus_service.dart';
import '../widgets/sign_out_button.dart';

class HodReviewSyllabusScreen extends StatelessWidget {
  final AppUser currentUser;
  final String classId;
  final String subjectId;
  final String term;

  const HodReviewSyllabusScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.subjectId,
    required this.term,
  });

  @override
  Widget build(BuildContext context) {
    final service = SyllabusService();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Syllabus Submissions'), actions: const [SignOutButton()]),
      body: StreamBuilder<List<SyllabusTopic>>(
        stream: service.watchPendingApproval(
          schoolId: currentUser.schoolId,
          classId: classId,
          subjectId: subjectId,
          term: term,
        ),
        builder: (context, snapshot) {
          final topics = snapshot.data ?? [];
          if (topics.isEmpty) {
            return const Center(child: Text('Nothing pending approval right now.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topic = topics[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(topic.title),
                  subtitle: Text('Covered ${topic.coveredAt?.toLocal().toString().split(' ')[0] ?? ''}'),
                  trailing: FilledButton(
                    onPressed: () => service.approveTopic(
                      schoolId: currentUser.schoolId,
                      topicId: topic.id,
                      hodUserId: currentUser.id,
                    ),
                    child: const Text('Approve'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}