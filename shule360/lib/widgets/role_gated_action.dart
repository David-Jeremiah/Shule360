import 'package:flutter/material.dart';
import '../permissions/permissions.dart';
import '../permissions/role.dart';

/// Shows a button only if [role] has [capability]. Used on the home screen
/// so adding a new feature never means writing a new permission check by
/// hand — just add one of these.
class RoleGatedAction extends StatelessWidget {
  final UserRole role;
  final Capability capability;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const RoleGatedAction({
    super.key,
    required this.role,
    required this.capability,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (!Permissions.can(role, capability)) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: Icon(icon),
          label: Text(label),
          onPressed: onTap,
        ),
      ),
    );
  }
}