import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/fee_record.dart';
import '../models/school_class.dart';
import '../models/student.dart';
import '../services/class_service.dart';
import '../services/fee_service.dart';
import '../services/student_service.dart';

class FeeManagementScreen extends StatefulWidget {
  final AppUser currentUser;
  final String term;

  const FeeManagementScreen({super.key, required this.currentUser, required this.term});

  @override
  State<FeeManagementScreen> createState() => _FeeManagementScreenState();
}

class _FeeManagementScreenState extends State<FeeManagementScreen> {
  final _feeService = FeeService();
  final _studentService = StudentService();
  final _classService = ClassService();
  SchoolClass? _selectedClass;

  Future<void> _recordPayment(Student student, FeeRecord? existing) async {
    final controller = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record payment — ${student.fullName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount paid (UGX)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (amount == null) return;

    final id = existing?.id ?? FirebaseFirestore.instance.collection('placeholder').doc().id;
    final updated = FeeRecord(
      id: id,
      schoolId: widget.currentUser.schoolId,
      studentId: student.id,
      term: widget.term,
      amountDue: existing?.amountDue ?? 0,
      amountPaid: (existing?.amountPaid ?? 0) + amount,
      dueDate: existing?.dueDate ?? DateTime.now().add(const Duration(days: 30)),
      gracePeriodDaysOverride: existing?.gracePeriodDaysOverride,
    );
    await _feeService.upsertFeeRecord(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fees & Defaulters')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<List<SchoolClass>>(
              stream: _classService.watchClasses(widget.currentUser.schoolId),
              builder: (context, snapshot) {
                final classes = snapshot.data ?? [];
                if (classes.isEmpty) {
                  return const Text('No classes yet — create one first.');
                }
                return DropdownButton<SchoolClass>(
                  isExpanded: true,
                  value: _selectedClass,
                  hint: const Text('Choose a class to view fees'),
                  items: classes
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (c) => setState(() => _selectedClass = c),
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedClass != null)
              Expanded(
                child: StreamBuilder<List<FeeRecord>>(
                  stream: _feeService.watchFeeRecords(
                    schoolId: widget.currentUser.schoolId,
                    term: widget.term,
                  ),
                  builder: (context, feeSnapshot) {
                    final feeRecordsByStudent = {
                      for (final r in feeSnapshot.data ?? <FeeRecord>[]) r.studentId: r,
                    };
                    return StreamBuilder<List<Student>>(
                      stream: _studentService.watchStudentsForClass(
                        schoolId: widget.currentUser.schoolId,
                        classId: _selectedClass!.id,
                      ),
                      builder: (context, studentSnapshot) {
                        final students = studentSnapshot.data ?? [];
                        if (students.isEmpty) {
                          return const Center(child: Text('No students in this class yet.'));
                        }
                        return ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            final student = students[index];
                            final record = feeRecordsByStudent[student.id];
                            final balance = record?.balance ?? 0;
                            final isDefaulter = record == null || !record.isFullyPaid;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                title: Text(student.fullName),
                                subtitle: Text(
                                  record == null
                                      ? 'No fee record yet'
                                      : 'Paid: ${record.amountPaid} / ${record.amountDue} (Balance: $balance)',
                                ),
                                trailing: isDefaulter
                                    ? const Icon(Icons.warning_amber, color: Colors.orange)
                                    : const Icon(Icons.check_circle, color: Colors.green),
                                onTap: () => _recordPayment(student, record),
                              ),
                            );
                          },
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