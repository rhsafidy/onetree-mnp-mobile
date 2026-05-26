// lib/screens/sync/sync_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/services/sync_service.dart';
import 'package:provider/provider.dart';
import '../../providers/sync_provider.dart';

class SyncScreen extends StatelessWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Synchronisation')),
      body: RefreshIndicator(
        onRefresh: sync.syncNow,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Status card ──────────────────────────────────────────────
            _StatusCard(sync: sync),
            const SizedBox(height: 20),

            // ── Sync now button ──────────────────────────────────────────
            ElevatedButton.icon(
              icon:  sync.isSyncing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              label: Text(sync.isSyncing ? 'Syncing…' : 'Sync now'),
              onPressed: sync.isSyncing || !sync.isOnline ? null : sync.syncNow,
            ),
            const SizedBox(height: 12),

            // ── Offline notice ────────────────────────────────────────────
            if (!sync.isOnline)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withAlpha(102)),
                ),
                child: const Row(children: [
                  Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No internet connection. Data will sync automatically when you reach a network point (within 3 hours after planting).',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ]),
              ),

            const SizedBox(height: 24),

            // ── Last result ───────────────────────────────────────────────
            if (sync.lastResult != null) ...[
              Text('Last sync result', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 10),
              _LastResultCard(result: sync.lastResult!),
            ],

            const SizedBox(height: 24),

            // ── Info box ──────────────────────────────────────────────────
            const _InfoBox(),
          ],
        ),
      ),
    );
  }
}

// ── Status card ───────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final SyncProvider sync;
  const _StatusCard({required this.sync});

  @override
  Widget build(BuildContext context) {
    final isOnline  = sync.isOnline;
    final color     = isOnline ? Colors.green : Colors.orange;
    final icon      = isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final statusTxt = isOnline ? 'Connected' : 'Offline';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          // Online indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:  color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(statusTxt, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
              const SizedBox(height: 4),
              Text(
                sync.hasPending
                    ? '${sync.pendingCount} item${sync.pendingCount > 1 ? 's' : ''} waiting to sync'
                    : 'All data is up to date',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          )),
          // Pending badge
          if (sync.hasPending)
            CircleAvatar(
              radius:          20,
              backgroundColor: Colors.orange,
              child: Text(
                '${sync.pendingCount}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ]),
      ),
    );
  }
}

// ── Last result card ──────────────────────────────────────────────────────────

class _LastResultCard extends StatelessWidget {
  final SyncResult result;
  const _LastResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _ResultStat(Icons.check_circle_outline, '${result.synced}', 'Synced',  Colors.green),
            _ResultStat(Icons.error_outline,         '${result.failed}', 'Failed',  Colors.red),
            _ResultStat(Icons.skip_next,             '${result.skipped}', 'Skipped', Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final IconData icon;
  final String   count;
  final String   label;
  final Color    color;
  const _ResultStat(this.icon, this.count, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 4),
      Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ]);
  }
}

// ── Info box ──────────────────────────────────────────────────────────────────

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        Colors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text('How sync works', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.blue)),
        ]),
        const SizedBox(height: 8),
        const Text(
          '• Data is saved locally first (offline-first).\n'
          '• Sync runs automatically when internet is detected.\n'
          '• After planting, you have up to 3 hours to reach a network point.\n'
          '• Failed items will retry up to 5 times.',
          style: TextStyle(fontSize: 12, height: 1.6, color: Colors.black87),
        ),
      ]),
    );
  }
}
