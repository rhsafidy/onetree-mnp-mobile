// lib/screens/tree_update/tree_update_photo_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/photo.dart';
import '../../models/tree.dart';
import 'tree_update_photo_viewmodel.dart';

class TreeUpdatePhotoScreen extends StatefulWidget {
  const TreeUpdatePhotoScreen({super.key});

  @override
  State<TreeUpdatePhotoScreen> createState() => _TreeUpdatePhotoScreenState();
}

class _TreeUpdatePhotoScreenState extends State<TreeUpdatePhotoScreen> {
  final _picker      = ImagePicker();
  PhotoType _type    = PhotoType.monthly;
  late Tree _tree;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tree = ModalRoute.of(context)!.settings.arguments as Tree;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TreeUpdatePhotoViewModel(),
      child: Scaffold(
        appBar: AppBar(title: Text('Add Photo — ${_tree.externalId}')),
        body: Consumer<TreeUpdatePhotoViewModel>(
          builder: (ctx, vm, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Photo type selector ────────────────────────────────────
              Text('Photo type', style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<PhotoType>(
                segments: const [
                  ButtonSegment(value: PhotoType.plantation, label: Text('Plantation'), icon: Icon(Icons.nature)),
                  ButtonSegment(value: PhotoType.monthly,    label: Text('Monthly'),    icon: Icon(Icons.calendar_month)),
                  ButtonSegment(value: PhotoType.replanting, label: Text('Replanting'), icon: Icon(Icons.refresh)),
                ],
                selected:  {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 24),

              // ── Preview ───────────────────────────────────────────────
              GestureDetector(
                onTap: () => _pickPhoto(ctx, vm),
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color:        Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: vm.hasPhoto
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(vm.selectedFile!, fit: BoxFit.cover),
                        )
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_a_photo_outlined, size: 56, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text('Tap to take a photo', style: TextStyle(color: Colors.grey[500])),
                        ]),
                ),
              ),
              const SizedBox(height: 12),

              // ── Camera / gallery buttons ──────────────────────────────
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon:  const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: () => _pickPhoto(ctx, vm, fromCamera: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon:  const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: () => _pickPhoto(ctx, vm, fromCamera: false),
                  ),
                ),
              ]),
              const SizedBox(height: 24),

              // ── Error ─────────────────────────────────────────────────
              if (vm.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(vm.error!, style: const TextStyle(color: Colors.red)),
                ),

              // ── Info box ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Photo will be uploaded to the server within ${AppConstants.syncMaxDelayHours} hours.',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // ── Save button ───────────────────────────────────────────
              ElevatedButton.icon(
                icon:  const Icon(Icons.save_outlined),
                label: vm.isSaving ? const Text('Saving…') : const Text('Save photo'),
                onPressed: vm.isSaving || !vm.hasPhoto
                    ? null
                    : () => _submit(ctx, vm),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(
    BuildContext ctx,
    TreeUpdatePhotoViewModel vm, {
    bool fromCamera = true,
  }) async {
    final xfile = await _picker.pickImage(
      source:       fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: AppConstants.photoQuality,
      maxWidth:     AppConstants.photoMaxWidthPx.toDouble(),
      maxHeight:    AppConstants.photoMaxHeightPx.toDouble(),
    );
    if (xfile != null) vm.setPhoto(File(xfile.path));
  }

  Future<void> _submit(BuildContext ctx, TreeUpdatePhotoViewModel vm) async {
    final ok = await vm.save(_tree.id, _type);
    if (ok && ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content:         Text('Photo saved. Will upload within 3 hours.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(ctx);
    }
  }
}
