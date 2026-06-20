import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../routes/app_routes.dart';
import 'data/auth_providers.dart';
import 'data/auth_service.dart';
import 'widgets/auth_header.dart';

/// Email + password sign-in screen.
///
/// Verifies credentials against the local [AuthService] (no backend): the user
/// must have registered first. On success it navigates to the home screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.prefilledEmail});

  /// Email carried over from the registration screen, pre-filled for convenience.
  final String? prefilledEmail;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final String? email = widget.prefilledEmail;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    // Simulate an authentication request against the local account store.
    await Future<void>.delayed(AppConstants.mediumAnimation);
    if (!mounted) return;

    final LoginResult result = ref.read(authServiceProvider).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    setState(() => _isSubmitting = false);

    switch (result) {
      case LoginResult.notRegistered:
        AppSnackbar.error(
          context,
          'No account found for that email. Please register first.',
        );
      case LoginResult.wrongPassword:
        AppSnackbar.error(context, 'Incorrect password. Please try again.');
      case LoginResult.success:
        ref.read(currentUserEmailProvider.notifier).state =
            _emailController.text.trim().toLowerCase();
        AppSnackbar.success(context, 'Welcome! You have logged in successfully.');
        context.go(AppRoutes.home);
    }
  }

  void _onForgotPassword() {
    AppSnackbar.info(context, 'Password reset is not available in this demo.');
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.spacingLg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const AuthHeader(
                      title: 'Welcome back',
                      subtitle: 'Sign in to continue to ${AppConstants.appName}',
                    ),
                    const SizedBox(height: AppConstants.spacingXl),
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: AppConstants.spacingMd),
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onFieldSubmitted: (_) => _submit(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingSm),
                    _RememberAndForgotRow(
                      rememberMe: _rememberMe,
                      onRememberChanged: (bool value) =>
                          setState(() => _rememberMe = value),
                      onForgotPassword: _onForgotPassword,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    CustomButton(
                      label: 'Sign In',
                      isLoading: _isSubmitting,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppConstants.spacingLg),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Don't have an account? ",
                          style: textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.register),
                          child: Text(
                            'Sign Up',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row with the "Remember me" checkbox and the "Forgot password?" link.
class _RememberAndForgotRow extends StatelessWidget {
  const _RememberAndForgotRow({
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Flexible(
          child: InkWell(
            onTap: () => onRememberChanged(!rememberMe),
            borderRadius: BorderRadius.circular(AppConstants.radiusSm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (bool? value) =>
                        onRememberChanged(value ?? false),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingSm),
                Flexible(
                  child: Text(
                    'Remember me',
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: onForgotPassword,
          child: Text(
            'Forgot password?',
            style: textTheme.labelLarge?.copyWith(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}
