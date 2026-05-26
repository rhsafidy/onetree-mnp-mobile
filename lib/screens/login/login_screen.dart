// lib/screens/login/login_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_app/core/navigation/app_route.dart';
import 'package:provider/provider.dart';
import 'login_viewmodel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool  _obscure      = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginViewModel(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              const Expanded(
                flex: 2,
                child: _Header(),
              ),
              // ── Form card ───────────────────────────────────────────────
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color:        Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.all(28),
                  child: _LoginForm(
                    formKey:      _formKey,
                    emailCtrl:    _emailCtrl,
                    passwordCtrl: _passwordCtrl,
                    obscure:      _obscure,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    onSubmit: _submit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext ctx, LoginViewModel vm) async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await vm.login(_emailCtrl.text, _passwordCtrl.text);
    if (!mounted || !ok) return;
    Navigator.pushReplacementNamed(ctx, AppRoutes.parcelList);
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.park, size: 64, color: Colors.white),
        const SizedBox(height: 12),
        Text(
          'Un Touriste — Un Arbre',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Madagascar National Parks',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState>  formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool                  obscure;
  final VoidCallback          onToggleObscure;
  final Future<void> Function(BuildContext, LoginViewModel) onSubmit;

  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Sign in', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('MNP Field Application', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 28),

          // Email
          TextFormField(
            controller:   emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration:   const InputDecoration(
              labelText:  'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller:    passwordCtrl,
            obscureText:   obscure,
            decoration:    InputDecoration(
              labelText:   'Password',
              prefixIcon:  const Icon(Icons.lock_outline),
              suffixIcon:  IconButton(
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 8),

          // Error message
          if (vm.errorMsg != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                vm.errorMsg!,
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            ),

          const Spacer(),

          // Submit button
          ElevatedButton(
            onPressed: vm.isLoading ? null : () => onSubmit(context, vm),
            child: vm.isLoading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
