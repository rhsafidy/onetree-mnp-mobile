// lib/screens/tree_update/tree_update_form_screen.dart

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/constants/db_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../models/tree.dart';
import 'tree_update_form_viewmodel.dart';

class TreeUpdateFormScreen extends StatefulWidget {
  const TreeUpdateFormScreen({super.key});

  @override
  State<TreeUpdateFormScreen> createState() => _TreeUpdateFormScreenState();
}

class _TreeUpdateFormScreenState extends State<TreeUpdateFormScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _heightCtrl  = TextEditingController();
  final _notesCtrl   = TextEditingController();

  String  _healthStatus = TreeHealthStatus.planted;
  double? _latitude;
  double? _longitude;
  bool    _fetchingGps = false;

  late Tree _tree;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tree = ModalRoute.of(context)!.settings.arguments as Tree;
    // Pre-fill existing values
    if (_tree.heightCm != null) _heightCtrl.text = '${_tree.heightCm}';
    if (_tree.healthStatus != null) _healthStatus = _tree.healthStatus!;
    if (_tree.notes != null) _notesCtrl.text = _tree.notes!;
    _latitude  = _tree.latitude;
    _longitude = _tree.longitude;
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TreeUpdateFormViewModel(),
      child: Scaffold(
        appBar: AppBar(title: Text('Update — ${_tree.externalId}')),
        body: Consumer<TreeUpdateFormViewModel>(
          builder: (ctx, vm, _) => Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Species info (read-only) ────────────────────────────
                _ReadOnlyField(
                  label: 'Species',
                  value: '${_tree.speciesVernacular ?? '—'}'
                         '${_tree.speciesScientific != null ? ' (${_tree.speciesScientific})' : ''}',
                ),
                const SizedBox(height: 8),
                _ReadOnlyField(label: 'Hole number', value: '${_tree.holeNumber ?? '—'}'),
                const SizedBox(height: 16),

                // ── Health status ────────────────────────────────────────
                Text('Health status', style: Theme.of(ctx).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TreeHealthStatus.planted,
                    TreeHealthStatus.monitored,
                    TreeHealthStatus.dead,
                    TreeHealthStatus.replaced,
                  ].map((s) => ChoiceChip(
                    label:     Text(s),
                    selected:  _healthStatus == s,
                    selectedColor: AppTheme.statusColor(s).withOpacity(0.2),
                    onSelected: (_) => setState(() => _healthStatus = s),
                    avatar:    Icon(AppTheme.statusIcon(s), size: 14, color: AppTheme.statusColor(s)),
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // ── Height ────────────────────────────────────────────────
                TextFormField(
                  controller:   _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration:   const InputDecoration(
                    labelText:  'Height (cm)',
                    prefixIcon: Icon(Icons.height),
                  ),
                  validator: (v) {
                    if (v != null && v.isNotEmpty && int.tryParse(v) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── GPS ───────────────────────────────────────────────────
                // ── GPS ───────────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GPS coordinates', style: Theme.of(ctx).textTheme.labelLarge),
                          const SizedBox(height: 4),
                          Text(
                            _latitude != null
                                ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                                : 'Not recorded yet',
                            style: TextStyle(
                              color:    _latitude != null ? Colors.green : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(  // ← wrap the button in a SizedBox
                      width: 140,
                      child: ElevatedButton.icon(
                        icon:  _fetchingGps
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.gps_fixed, size: 18),
                        label: const Text('Record GPS'),
                        onPressed: _fetchingGps ? null : _recordGps,
                      ),
                    ),
                  ],
                ),
                // ── Notes ─────────────────────────────────────────────────
                TextFormField(
                  controller:  _notesCtrl,
                  maxLines:    3,
                  decoration:  const InputDecoration(
                    labelText:  'Notes',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Error ─────────────────────────────────────────────────
                if (vm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                  ),

                // ── Save ──────────────────────────────────────────────────
                ElevatedButton.icon(
                  icon:  const Icon(Icons.save_outlined),
                  label: vm.isSaving
                      ? const Text('Saving…')
                      : const Text('Save update'),
                  onPressed: vm.isSaving ? null : () => _submit(ctx, vm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _recordGps() async {
    setState(() => _fetchingGps = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('GPS permission denied')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitude  = pos.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('GPS error: $e')),
        );
      }
    } finally {
      setState(() => _fetchingGps = false);
    }
  }

  Future<void> _submit(BuildContext ctx, TreeUpdateFormViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await vm.saveUpdate(
      original:     _tree,
      heightCm:     _heightCtrl.text.isNotEmpty ? int.tryParse(_heightCtrl.text) : null,
      healthStatus: _healthStatus,
      latitude:     _latitude,
      longitude:    _longitude,
      notes:        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    if (ok && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Saved locally. Will sync within 3 hours.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(ctx);
    }
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;
  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(value, style: const TextStyle(fontSize: 14)),
    );
  }
}
