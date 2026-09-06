import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/constants/app_constants.dart';
import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/theme/app_theme.dart';
import 'package:keychain_shop/utils/validators.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/app_text_field.dart';
import 'package:keychain_shop/widgets/brand_mark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

    final ok = await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (ok) {
      context.go('/home');
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
              Color(0xFFF3E6D6),
              AppColors.background,
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
                  const SizedBox(height: 20),
                  const BrandMark(size: 64),
                  const SizedBox(height: 28),
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue shopping at ${AppConstants.appName}.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.lg),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      children: [
                        AppTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'you@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscure,
                          onToggleObscure: () =>
                              setState(() => _obscure = !_obscure),
                          textInputAction: TextInputAction.done,
                          validator: Validators.password,
                          onFieldSubmitted: (_) => _submit(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        AppButton(
                          label: 'Sign In',
                          isLoading: isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/admin/login'),
                      child: const Text('Admin login'),
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
