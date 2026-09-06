import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:keychain_shop/providers/auth_provider.dart';
import 'package:keychain_shop/utils/validators.dart';
import 'package:keychain_shop/widgets/app_button.dart';
import 'package:keychain_shop/widgets/app_text_field.dart';
import 'package:keychain_shop/widgets/brand_mark.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    auth.clearError();

    final ok = await auth.sendPasswordReset(_emailController.text);

    if (!mounted) return;

    if (ok) {
      setState(() => _sent = true);
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reset password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(
                      size: 72,
                      icon: Icons.mark_email_read_outlined,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Check your email',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a password reset link to ${_emailController.text.trim()}. '
                      'Follow the link to set a new password.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    AppButton(
                      label: 'Back to Sign In',
                      onPressed: () => context.go('/login'),
                    ),
                  ],
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Forgot your password?',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enter your account email and we will send a reset link via Firebase Authentication.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: Validators.email,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        label: 'Send reset link',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
