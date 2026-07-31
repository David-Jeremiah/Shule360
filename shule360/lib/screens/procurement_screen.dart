import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/procurement_item.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';
import '../services/procurement_service.dart';

class ProcurementScreen extends StatefulWidget {
  final AppUser currentUser;

  const ProcurementScreen({super.key, required this.currentUser});

  @override
  State<ProcurementScreen> createState() => _ProcurementScreenState();
}

class _ProcurementScreenState extends State<ProcurementScreen> {
  final _service = ProcurementService();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();

  Future<void> _submitRequest() async {
    final name = _itemNameController.text.trim();
    final qty = int.tryParse(_quantityController.text.trim());
    final cost = double.tryParse(_costController.text.trim());
    if (name.isEmpty || qty == null || cost == null) return;

    final id = FirebaseFirestore.instance.collection('placeholder').doc().id;
    await _service.requestItem(ProcurementItem(
      id: id,
      schoolId: widget.currentUser.schoolId,
      itemName: name,
      quantity: qty,
      estimatedCost: cost,
      requestedByUserId: widget.currentUser.id,
      requestedAt: DateTime.now(),
    ));
    _itemNameController.clear();
    _quantityController.clear();
    _costController.clear();
  }

  Color _statusColor(ProcurementStatus s) {
    switch (s) {
      case ProcurementStatus.requested:
        return Colors.orange;
      case ProcurementStatus.approved:
        return Colors.blue;
      case ProcurementStatus.rejected:
        return Colors.red;
      case ProcurementStatus.purchased:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApprove = Permissions.can(widget.currentUser.role, Capability.editProcurement);

    return Scaffold(
      appBar: AppBar(title: const Text('Procurement')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Purchase Request', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(labelText: 'Item'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Est. cost (UGX)'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _submitRequest, icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 24),
            Text('Requests', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<ProcurementItem>>(
                stream: _service.watchAll(widget.currentUser.schoolId),
                builder: (context, snapshot) {
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) return const Text('No procurement requests yet.');
                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('${item.itemName} x${item.quantity}'),
                          subtitle: Text('Est. cost: ${item.estimatedCost}'
                              '${item.supplierName != null ? ' • Supplier: ${item.supplierName}' : ''}'),
                          trailing: canApprove && item.status == ProcurementStatus.requested
                              ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _service.updateStatus(
                                  schoolId: widget.currentUser.schoolId,
                                  itemId: item.id,
                                  status: ProcurementStatus.approved,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _service.updateStatus(
                                  schoolId: widget.currentUser.schoolId,
                                  itemId: item.id,
                                  status: ProcurementStatus.rejected,
                                ),
                              ),
                            ],
                          )
                              : Chip(
                            label: Text(item.status.name),
                            backgroundColor: _statusColor(item.status).withOpacity(0.15),
                            labelStyle: TextStyle(color: _statusColor(item.status)),
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