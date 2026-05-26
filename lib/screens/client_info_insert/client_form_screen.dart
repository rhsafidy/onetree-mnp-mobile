// lib/screens/client_info_insert/client_form_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tree.dart';
import 'client_form_screen_viewmodel.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key});

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _natCtrl      = TextEditingController();
  final _phoneCtrl    = TextEditingController();

  late Tree _tree;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tree = ModalRoute.of(context)!.settings.arguments as Tree;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _natCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClientFormViewModel(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Tourist registration')),
        body: Consumer<ClientFormViewModel>(
          builder: (ctx, vm, _) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Tree summary ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color:        Theme.of(ctx).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:       Border.all(color: Theme.of(ctx).colorScheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.park, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(
                        _tree.speciesVernacular ?? _tree.speciesScientific ?? _tree.externalId,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'QR: ${_tree.externalId} • Hole ${_tree.holeNumber ?? '—'}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ])),
                  ]),
                ),
                const SizedBox(height: 24),

                Text('Tourist information', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // ── Name (required) ──────────────────────────────────────
                TextFormField(
                  controller:         _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText:  'Full name *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),

                // ── Email (optional) ─────────────────────────────────────
                TextFormField(
                  controller:   _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText:  'Email address (optional)',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText:   'Leave empty if unavailable',
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && !v.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── Nationality ──────────────────────────────────────────
                TextFormField(
                  controller:         _natCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText:  'Nationality',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Phone ────────────────────────────────────────────────
                TextFormField(
                  controller:   _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText:  'Phone number',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 24),

                // ── No-email notice ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:        Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:       Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Email is optional. Tourists without email will still receive a physical QR card to track their tree.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // ── Error ────────────────────────────────────────────────
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                  ),

                // ── Confirm button ────────────────────────────────────────
                ElevatedButton.icon(
                  icon:  const Icon(Icons.assignment_turned_in_outlined),
                  label: vm.isSaving
                      ? const Text('Registering…')
                      : const Text('Confirm assignment'),
                  onPressed: vm.isSaving ? null : () => _submit(ctx, vm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext ctx, ClientFormViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await vm.save(
      tree:        _tree,
      name:        _nameCtrl.text.trim(),
      email:       _emailCtrl.text.trim(),
      nationality: _natCtrl.text.trim(),
      phone:       _phoneCtrl.text.trim(),
    );

    if (ok && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            '${_nameCtrl.text.trim()} assigned to ${_tree.externalId}. '
            'Sync pending.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      // Pop back to parcel list (pop ×2: form + scanner)
      Navigator.popUntil(ctx, (r) => r.isFirst);
    }
  }
}
