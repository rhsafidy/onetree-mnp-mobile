// lib/screens/trees_list/tree_list_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/parcel.dart';
import '../../models/tree.dart';
import 'trees_list_viewmodel.dart';

class TreesListScreen extends StatelessWidget {
  const TreesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final parcel = ModalRoute.of(context)!.settings.arguments as Parcel;

    return ChangeNotifierProvider(
      create: (_) => TreesListViewModel()..load(parcel),
      child: _TreesListView(parcel: parcel),
    );
  }
}

class _TreesListView extends StatelessWidget {
  final Parcel parcel;
  const _TreesListView({required this.parcel});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TreesListViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parcel.name, style: const TextStyle(fontSize: 16)),
            Text(parcel.code, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(children: [
        // ── Search & filter bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(children: [
            Expanded(
              child: TextField(
                onChanged: vm.setSearch,
                decoration: const InputDecoration(
                  hintText:  'Search species or QR…',
                  prefixIcon: Icon(Icons.search),
                  isDense:   true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _StatusFilterChip(vm: vm),
          ]),
        ),
        const SizedBox(height: 8),

        // ── List ─────────────────────────────────────────────────────────
        Expanded(child: Builder(builder: (_) {
          if (vm.isLoading) return const Center(child: CircularProgressIndicator());
          if (vm.error != null) return Center(child: Text(vm.error!));
          if (vm.trees.isEmpty) {
            return const Center(
              child: Text('No trees found.', style: TextStyle(color: Colors.grey)),
            );
          }
          return RefreshIndicator(
            onRefresh: () => vm.load(parcel),
            child: ListView.separated(
              padding:          const EdgeInsets.all(12),
              itemCount:        vm.trees.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) => _TreeTile(
                tree: vm.trees[i],
                onTap: () => Navigator.pushNamed(
                  ctx, AppRoutes.treeDetail,
                  arguments: vm.trees[i],
                ),
              ),
            ),
          );
        })),
      ]),
    );
  }
}

// ── Tree tile ─────────────────────────────────────────────────────────────────

class _TreeTile extends StatelessWidget {
  final Tree tree;
  final VoidCallback onTap;
  const _TreeTile({required this.tree, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(tree.healthStatus);
    final icon  = AppTheme.statusIcon(tree.healthStatus);

    return Card(
      child: ListTile(
        onTap:   onTap,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha((0.15 * 255).round()),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          tree.speciesVernacular ?? tree.speciesScientific ?? tree.externalId,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tree.speciesVernacular != null && tree.speciesScientific != null)
              Text(tree.speciesScientific!, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
            Row(children: [
              const Icon(Icons.tag, size: 11, color: Colors.grey),
              const SizedBox(width: 2),
              Text('Hole ${tree.holeNumber ?? '—'}   •   ${tree.externalId}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ],
        ),
        trailing: tree.syncPending
            ? const Icon(Icons.cloud_upload_outlined, size: 16, color: Colors.orange)
            : null,
        isThreeLine: true,
      ),
    );
  }
}

// ── Status filter chip ────────────────────────────────────────────────────────

class _StatusFilterChip extends StatelessWidget {
  final TreesListViewModel vm;
  const _StatusFilterChip({required this.vm});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      tooltip:      'Filter by status',
      icon:         const Icon(Icons.filter_list),
      initialValue: vm.statusFilter,
      onSelected:   vm.setStatusFilter,
      itemBuilder:  (_) => TreesListViewModel.statusOptions
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(children: [
                  if (s != null) Icon(AppTheme.statusIcon(s), size: 16, color: AppTheme.statusColor(s)),
                  if (s != null) const SizedBox(width: 8),
                  Text(s ?? 'All statuses'),
                ]),
              ))
          .toList(),
    );
  }
}
