// lib/screens/client_info_insert/qr_scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/tree.dart';
import 'qr_scanner_viewmodel.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QRScannerViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan QR Code'),
          actions: [
            Consumer<QRScannerViewModel>(
              builder: (_, vm, __) => vm.state != QRScanState.scanning
                  ? IconButton(
                      icon:     const Icon(Icons.refresh),
                      tooltip:  'Scan again',
                      onPressed: vm.reset,
                    )
                  : IconButton(
                      icon:     const Icon(Icons.flash_on),
                      onPressed: _controller.toggleTorch,
                    ),
            ),
          ],
        ),
        body: Consumer<QRScannerViewModel>(
          builder: (ctx, vm, _) {
            if (vm.state == QRScanState.scanning || vm.state == QRScanState.loading) {
              return Stack(children: [
                // Camera preview
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) {
                    final code = capture.barcodes.firstOrNull?.rawValue;
                    if (code != null) vm.handleScan(code);
                  },
                ),
                // Viewfinder overlay
                const _ScanOverlay(),
                // Loading spinner
                if (vm.state == QRScanState.loading)
                  const Center(child: CircularProgressIndicator(color: Colors.white)),
              ]);
            }

            return _ResultView(vm: vm, onNavigate: () => _navigateToForm(ctx, vm.tree!));
          },
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext ctx, Tree tree) {
    Navigator.pushNamed(ctx, AppRoutes.clientForm, arguments: tree);
  }
}

// ── Scan overlay ──────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  const _ScanOverlay();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Spacer(),
      Center(
        child: Container(
          width: 240, height: 240,
          decoration: BoxDecoration(
            border:       Border.all(color: Colors.green, width: 3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(mainAxisAlignment: MainAxisAlignment.end, children: [
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Align QR code within the frame',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ]),
        ),
      ),
      const Spacer(),
    ]);
  }
}

// ── Result view ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final QRScannerViewModel vm;
  final VoidCallback onNavigate;
  const _ResultView({required this.vm, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    switch (vm.state) {
      case QRScanState.found:
        return _SuccessView(tree: vm.tree!, onContinue: onNavigate, onRescan: vm.reset);

      case QRScanState.alreadyUsed:
        return _StatusView(
          icon:    Icons.warning_amber_rounded,
          color:   Colors.orange,
          title:   'QR code already assigned',
          message: 'This QR code (${vm.tree?.externalId}) is already linked to a tourist.',
          onRescan: vm.reset,
        );

      case QRScanState.notFound:
        return _StatusView(
          icon:    Icons.search_off,
          color:   Colors.red,
          title:   'QR code not found',
          message: 'Code "${vm.scannedId}" does not exist in the local database.',
          onRescan: vm.reset,
        );

      case QRScanState.error:
        return _StatusView(
          icon:    Icons.error_outline,
          color:   Colors.red,
          title:   'Error',
          message: vm.error ?? 'Unknown error',
          onRescan: vm.reset,
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _SuccessView extends StatelessWidget {
  final Tree tree;
  final VoidCallback onContinue;
  final VoidCallback onRescan;
  const _SuccessView({required this.tree, required this.onContinue, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 72),
        const SizedBox(height: 16),
        Text('QR Code found!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Card(child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _InfoRow('QR Code', tree.externalId),
            _InfoRow('Species', tree.speciesVernacular ?? '—'),
            _InfoRow('Hole', '${tree.holeNumber ?? '—'}'),
            _InfoRow('Status', tree.healthStatus ?? '—'),
          ]),
        )),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Assign to tourist'),
          onPressed: onContinue,
        ),
        const SizedBox(height: 12),
        TextButton(onPressed: onRescan, child: const Text('Scan another code')),
      ]),
    );
  }
}

class _StatusView extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title;
  final String   message;
  final VoidCallback onRescan;
  const _StatusView({required this.icon, required this.color, required this.title, required this.message, required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 72),
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan again'),
          onPressed: onRescan,
        ),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ]),
    );
  }
}
