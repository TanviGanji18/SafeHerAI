import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/sos_provider.dart';
import '../providers/auth_provider.dart';
import '../models/sos_model.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({Key? key}) : super(key: key);

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final sos = Provider.of<SOSProvider>(context, listen: false);
      sos.loadContacts(auth.user?.id ?? 'anonymous_user');
    });
  }

  void _showContactDialog({TrustedContact? contactToEdit}) {
    final isEditing = contactToEdit != null;
    final nameCtrl = TextEditingController(text: contactToEdit?.name ?? '');
    final phoneCtrl = TextEditingController(text: contactToEdit?.phone ?? '+91');
    String relationship = contactToEdit?.relationship ?? 'Family';
    bool isPrimary = contactToEdit?.isPrimary ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEditing ? 'Edit Trusted Contact' : 'Add Trusted Contact',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Contact Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Emergency Phone (+91)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: ['Family', 'Parent', 'Sibling', 'Friend', 'Guardian', 'Colleague'].contains(relationship)
                          ? relationship
                          : 'Family',
                      decoration: const InputDecoration(labelText: 'Relationship'),
                      items: ['Family', 'Parent', 'Sibling', 'Friend', 'Guardian', 'Colleague']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => relationship = val ?? 'Family'),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Primary Contact', style: TextStyle(fontSize: 14)),
                      value: isPrimary,
                      onChanged: (v) => setDialogState(() => isPrimary = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().length > 5) {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final sos = Provider.of<SOSProvider>(context, listen: false);
                      final userId = auth.user?.id ?? 'anonymous_user';

                      if (isEditing) {
                        final contactId = contactToEdit.id ?? contactToEdit.phone;
                        await sos.updateContact(
                          userId,
                          contactId,
                          TrustedContact(
                            id: contactId,
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            relationship: relationship,
                            isPrimary: isPrimary,
                          ),
                        );
                      } else {
                        await sos.addContact(
                          userId,
                          TrustedContact(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            relationship: relationship,
                            isPrimary: isPrimary,
                          ),
                        );
                      }
                      if (mounted) Navigator.of(ctx).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Contact'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContact(TrustedContact contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Contact?'),
        content: Text('Are you sure you want to remove ${contact.name} from your trusted emergency contacts?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final sos = Provider.of<SOSProvider>(context, listen: false);
              final contactId = contact.id ?? contact.phone;
              await sos.deleteContact(auth.user?.id ?? 'anonymous_user', contactId);
              if (mounted) Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sosProv = Provider.of<SOSProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isGuest = auth.isGuest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Contact', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isGuest)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Guest Mode: Added contacts are kept during your current session. Sign in to sync and protect contacts across devices.',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'These contacts automatically receive your emergency distress signal and live GPS location when SOS is activated.',
                      style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (sosProv.contacts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No contacts added yet. Tap Add Contact below.'),
                ),
              )
            else
              ...sosProv.contacts.map((c) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.isPrimary ? AppColors.safeGreen : AppColors.primary.withOpacity(0.15),
                      child: Icon(
                        c.isPrimary ? Icons.star : Icons.person,
                        color: c.isPrimary ? Colors.white : AppColors.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.safeGreen.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PRIMARY',
                              style: TextStyle(fontSize: 10, color: AppColors.safeGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text('${c.relationship} • ${c.phone}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit Contact',
                          onPressed: () => _showContactDialog(contactToEdit: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.emergencyRed),
                          tooltip: 'Delete Contact',
                          onPressed: () => _confirmDeleteContact(c),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
