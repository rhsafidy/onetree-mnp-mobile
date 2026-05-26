// lib/screens/tree_details/tree_details_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/photo.dart';
import '../../models/tree.dart';
import 'tree_details_viewmodel.dart';

class TreeDetailsScreen extends StatelessWidget {
  const TreeDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tree = ModalRoute.of(context)!.settings.arguments as Tree;

    return ChangeNotifierProvider(
      create: (_) => TreeDetailsViewModel()..load(tree),
      child: const _TreeDetailsView(),
    );
  }
}

class _TreeDetailsView extends StatelessWidget {
  const _TreeDetailsView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TreeDetailsViewModel>();
    if (vm.tree == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final tree  = vm.tree!;
    final color = AppTheme.statusColor(tree.healthStatus);

    return Scaffold(
      appBar: AppBar(
        title: Text(tree.speciesVernacular ?? tree.externalId),
        actions: [
          IconButton(
            tooltip:  'Update tree',
            icon:     const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.pushNamed(
              context, AppRoutes.treeUpdate,
              arguments: tree,
            ).then((_) => vm.refresh()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.refresh,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Status banner ───────────────────────────────────────────
            _StatusBanner(tree: tree, color: color),
            const SizedBox(height: 16),

            // ── Info card ────────────────────────────────────────────────
            _InfoSection(tree: tree),
            const SizedBox(height: 16),

            // ── Tourist card ─────────────────────────────────────────────
            if (tree.touristId != null) ...[
              _SectionTitle('Sponsor'),
              const _TouristCard(),
              const SizedBox(height: 16),
            ],

            // ── Photos ───────────────────────────────────────────────────
            _SectionTitle('Photos (${vm.photos.length})'),
            const SizedBox(height: 8),
            if (vm.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (vm.photos.isEmpty)
              const Text('No photos yet.', style: TextStyle(color: Colors.grey))
            else
              _PhotoGrid(photos: vm.photos),
            const SizedBox(height: 16),

            // ── Add photo button ─────────────────────────────────────────
            OutlinedButton.icon(
              icon:     const Icon(Icons.add_a_photo_outlined),
              label:    const Text('Add monthly photo'),
              onPressed: () => Navigator.pushNamed(
                context, AppRoutes.treePhoto,
                arguments: tree,
              ).then((_) => vm.refresh()),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  final Tree  tree;
  final Color color;
  const _StatusBanner({required this.tree, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        border:       Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(AppTheme.statusIcon(tree.healthStatus), color: color, size: 28),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            tree.healthStatus?.toUpperCase() ?? 'PENDING',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
          if (tree.plantationDate != null)
            Text(
              'Planted on ${_fmt(tree.plantationDate!)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
        ]),
        const Spacer(),
        if (tree.syncPending)
          Chip(
            label:     const Text('Pending sync', style: TextStyle(fontSize: 11)),
            avatar:    const Icon(Icons.cloud_upload_outlined, size: 14),
            padding:   EdgeInsets.zero,
            backgroundColor: Colors.orange.withValues(alpha: 0.1),
          ),
      ]),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ── Info section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Tree tree;
  const _InfoSection({required this.tree});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionTitle('Tree information'),
          const SizedBox(height: 12),
          _Row('QR Code',         tree.externalId),
          _Row('Species',         tree.speciesVernacular ?? '—'),
          _Row('Scientific name', tree.speciesScientific ?? '—', italic: true),
          _Row('Family',          tree.family ?? '—'),
          _Row('Hole number',     '${tree.holeNumber ?? '—'}'),
          _Row('Height',          tree.heightCm != null ? '${tree.heightCm} cm' : '—'),
          if (tree.latitude != null)
            _Row('GPS', '${tree.latitude!.toStringAsFixed(6)}, ${tree.longitude!.toStringAsFixed(6)}'),
          if (tree.planterName != null)
            _Row('Planted by', '${tree.planterName} (${tree.planterFunction ?? ''})'),
          if (tree.notes != null && tree.notes!.isNotEmpty)
            _Row('Notes', tree.notes!),
        ]),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool   italic;
  const _Row(this.label, this.value, {this.italic = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize:   13,
              fontStyle:  italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ]),
    );
  }
}

class _TouristCard extends StatelessWidget {
  const _TouristCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.person_outline),
        title:   Text('Tourist info'),
        subtitle: Text('Load from TouristRepository'),
      ),
    );
  }
}

// ── Photos ────────────────────────────────────────────────────────────────────

class _PhotoGrid extends StatelessWidget {
  final List<Photo> photos;
  const _PhotoGrid({required this.photos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap:  true,
      physics:     const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: photos.length,
      itemBuilder: (_, i) {
        final photo = photos[i];
        final hasLocal = photo.localPath != null && File(photo.localPath!).existsSync();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasLocal
              ? Image.file(File(photo.localPath!), fit: BoxFit.cover)
              : (photo.url.isNotEmpty
                  ? Image.network(photo.url, fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                    )),
        );
      },
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
