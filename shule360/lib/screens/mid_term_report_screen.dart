import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/mid_term_report_service.dart';

class MidTermReportScreen extends StatefulWidget {
  final AppUser currentUser;
  final String classId;
  final String term;

  const MidTermReportScreen({
    super.key,
    required this.currentUser,
    required this.classId,
    required this.term,
  });

  @override
  State<MidTermReportScreen> createState() => _MidTermReportScreenState();
}

class _MidTermReportScreenState extends State<MidTermReportScreen> {
  final _service = MidTermReportService();
  List<SubjectPassRate>? _results;
  bool _isGenerating = false;

  Future<void> _generate() async {
    setState(() => _isGenerating = true);
    try {
      final results = await _service.generateMidTermReport(
        schoolId: widget.currentUser.schoolId,
        classId: widget.classId,
        term: widget.term,
      );
      setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mid-Term Pass/Fail Report')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generate,
              icon: const Icon(Icons.analytics),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Mid-Term Report'),
            ),
            const SizedBox(height: 24),
            if (_results != null)
              Expanded(
                child: _results!.isEmpty
                    ? const Text('No mid-term marks entered yet for this class.')
                    : ListView.builder(
                  itemCount: _results!.length,
                  itemBuilder: (context, index) {
                    final r = _results![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text('Subject: ${r.subjectId}'),
                        subtitle: Text('${r.passCount} / ${r.totalStudents} passed'),
                        trailing: Text(
                          '${r.passRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: r.passRate >= 50 ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
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