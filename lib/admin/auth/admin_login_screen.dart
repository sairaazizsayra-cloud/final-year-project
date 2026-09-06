import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/validators.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/app_text_field.dart';
import 'package:keychain_shop/widgets/brand_mark.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.signInAsAdmin(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      context.go('/admin');
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C3E50),
              Color(0xFF1A252F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(
                      '← Customer login',
                      style: TextStyle(color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const BrandMark(
                    size: 64,
                    icon: Icons.admin_panel_settings_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Admin Panel',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in with an admin Firebase account to manage the shop.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                    ),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _emailController,
                          label: 'Admin email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscure,
                          onToggleObscure: () =>
                              setState(() => _obscure = !_obscure),
                          textInputAction: TextInputAction.done,
                          validator: Validators.password,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Sign in as Admin',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tip: create a user in Firebase Auth, then set users/{uid}.role = "admin" in Firestore.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white60,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
