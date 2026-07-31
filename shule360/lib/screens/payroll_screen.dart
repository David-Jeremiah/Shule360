import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/payroll_record.dart';
import '../services/payroll_service.dart';

class PayrollScreen extends StatefulWidget {
  final AppUser currentUser;

  const PayrollScreen({super.key, required this.currentUser});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final _service = PayrollService();
  final _staffIdController = TextEditingController();
  final _grossController = TextEditingController();
  final _deductionsController = TextEditingController();
  final String _month = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

  Future<void> _generate() async {
    final gross = double.tryParse(_grossController.text.trim());
    final deductions = double.tryParse(_deductionsController.text.trim()) ?? 0;
    final staffId = _staffIdController.text.trim();
    if (gross == null || staffId.isEmpty) return;

    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.generatePayslip(PayrollRecord(
      id: id,
      schoolId: widget.currentUser.schoolId,
      staffUserId: staffId,
      month: _month,
      grossSalary: gross,
      deductions: deductions,
      generatedAt: DateTime.now(),
    ));
    _staffIdController.clear();
    _grossController.clear();
    _deductionsController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payroll — $_month')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _staffIdController,
              decoration: const InputDecoration(labelText: 'Staff user ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _grossController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Gross salary (UGX)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deductionsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Deductions (UGX)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _generate, child: const Text('Generate Payslip')),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<List<PayrollRecord>>(
                stream: _service.watchPayrollForMonth(schoolId: widget.currentUser.schoolId, month: _month),
                builder: (context, snapshot) {
                  final records = snapshot.data ?? [];
                  if (records.isEmpty) return const Text('No payslips generated yet this month.');
                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('Staff: ${r.staffUserId}'),
                          subtitle: Text('Gross: ${r.grossSalary}  Deductions: ${r.deductions}'),
                          trailing: Text('Net: ${r.netSalary}', style: const TextStyle(fontWeight: FontWeight.bold)),
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