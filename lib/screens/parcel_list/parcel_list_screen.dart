// lib/screens/parcel_list/parcel_list_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import '../../models/parcel.dart';
import '../../providers/sync_provider.dart';
import '../../services/session_service.dart';
import 'parcel_list_viewmodel.dart';

class ParcelListScreen extends StatelessWidget {
  const ParcelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ParcelListViewModel()..load(),
      child: const _ParcelListView(),
    );
  }
}

class _ParcelListView extends StatelessWidget {
  const _ParcelListView();

  @override
  Widget build(BuildContext context) {
    final vm   = context.watch<ParcelListViewModel>();
    final sync = context.watch<SyncProvider>();
    final user = SessionService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Restoration Parcels'),
        actions: [
          // Sync badge
          IconButton(
            tooltip: '${sync.pendingCount} pending sync',
            icon: Stack(
              children: [
                const Icon(Icons.cloud_sync_outlined),
                if (sync.hasPending)
                  Positioned(
                    right: 0, top: 0,
                    child: CircleAvatar(
                      radius:          7,
                      backgroundColor: Colors.orange,
                      child: Text(
                        '${sync.pendingCount}',
                        style: const TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.sync),
          ),
          // QR scanner (receptionist only)
          if (user?.role.name == 'receptionist' || user?.role.name == 'admin')
            IconButton(
              tooltip: 'Scan QR Code',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.qrScanner),
            ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'logout') {
                await SessionService.instance.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'user',
                enabled: false,
                child: Text(user?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
          ),
        ],
      ),
      body: Builder(builder: (_) {
        if (vm.isLoading) return const Center(child: CircularProgressIndicator());
        if (vm.error != null) return _ErrorView(message: vm.error!, onRetry: vm.load);
        if (vm.parcels.isEmpty) return const _EmptyView();

        return RefreshIndicator(
          onRefresh: vm.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount:     vm.parcels.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) => _ParcelCard(
              parcel:     vm.parcels[i],
              treeCount:  vm.treeCountFor(vm.parcels[i].id),
              onTap: () => Navigator.pushNamed(
                ctx,
                AppRoutes.treesList,
                arguments: vm.parcels[i],
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Parcel card ───────────────────────────────────────────────────────────────

class _ParcelCard extends StatelessWidget {
  final Parcel parcel;
  final int    treeCount;
  final VoidCallback onTap;

  const _ParcelCard({required this.parcel, required this.treeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      parcel.code,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 10),
              Text(parcel.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              if (parcel.park != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(parcel.park!, style: Theme.of(context).textTheme.bodySmall),
                ]),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _Stat(icon: Icons.park, label: '$treeCount trees'),
                  const SizedBox(width: 16),
                  if (parcel.areaHa != null)
                    _Stat(icon: Icons.square_foot, label: '${parcel.areaHa} ha'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _Stat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 4),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
    ]));
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.forest_outlined, size: 64, color: Colors.grey),
      SizedBox(height: 12),
      Text('No parcels found.', style: TextStyle(color: Colors.grey)),
    ]));
  }
}
