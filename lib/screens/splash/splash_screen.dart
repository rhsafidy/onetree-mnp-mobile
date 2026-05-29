// lib/screens/splash/splash_screen.dart
//
// Shown at app startup. Checks connectivity, pulls latest data from server,
// then routes to login or parcel list depending on session state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'splash_viewmodel.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SplashViewModel()..start(context),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SplashViewModel>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Logo + titre ─────────────────────────────────────────────
            const Expanded(
              flex: 3,
              child: _LogoSection(),
            ),

            // ── Étapes de démarrage ──────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Barre de progression
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value:            vm.progress,
                        minHeight:        6,
                        backgroundColor:  Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message de l'étape courante
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        vm.currentStep,
                        key: ValueKey(vm.currentStep),
                        style: const TextStyle(
                          color:     Colors.white,
                          fontSize:  14,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Liste des étapes avec icônes
                    ..._SplashStepTile.buildAll(vm.steps),
                  ],
                ),
              ),
            ),

            // ── Version / Copyright ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                'Madagascar National Parks — DSII v1.0.0',
                style: TextStyle(
                  color:    Colors.white.withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icône principale
        Container(
          width:  110,
          height: 110,
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.15),
            shape:        BoxShape.circle,
            border:       Border.all(color: Colors.white30, width: 2),
          ),
          child: const Icon(Icons.park, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          'Un Touriste',
          style: TextStyle(
            color:      Colors.white,
            fontSize:   28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const Text(
          'Un Arbre',
          style: TextStyle(
            color:      Colors.white70,
            fontSize:   22,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Madagascar National Parks',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ── Step tile ─────────────────────────────────────────────────────────────────

class _SplashStepTile extends StatelessWidget {
  final SplashStep step;
  const _SplashStepTile({required this.step});

  static List<Widget> buildAll(List<SplashStep> steps) {
    return steps
        .map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _SplashStepTile(step: s),
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final icon  = _iconFor(step.status);
    final color = _colorFor(step.status);

    return Row(
      children: [
        SizedBox(
          width:  22,
          height: 22,
          child:  icon,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            step.label,
            style: TextStyle(
              color:      color,
              fontSize:   13,
              fontWeight: step.status == StepStatus.running
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
        if (step.detail != null)
          Text(
            step.detail!,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
      ],
    );
  }

  Widget _iconFor(StepStatus status) {
    switch (status) {
      case StepStatus.waiting:
        return const Icon(Icons.radio_button_unchecked,
            size: 18, color: Colors.white24);
      case StepStatus.running:
        return const SizedBox(
          width:  18,
          height: 18,
          child:  CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case StepStatus.done:
        return const Icon(Icons.check_circle, size: 18, color: Colors.green);
      case StepStatus.skipped:
        return const Icon(Icons.remove_circle_outline,
            size: 18, color: Colors.white38);
      case StepStatus.error:
        return const Icon(Icons.warning_amber_rounded,
            size: 18, color: Colors.orange);
    }
  }

  Color _colorFor(StepStatus status) {
    switch (status) {
      case StepStatus.done:    return Colors.white;
      case StepStatus.running: return Colors.white;
      case StepStatus.error:   return Colors.orange;
      default:                 return Colors.white38;
    }
  }
}
