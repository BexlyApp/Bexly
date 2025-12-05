import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:toastification/toastification.dart';
import 'package:bexly/core/riverpod/auth_providers.dart';
import 'package:bexly/core/components/form_fields/custom_input_border.dart';
import 'package:bexly/core/constants/app_colors.dart';
import 'package:bexly/core/constants/app_spacing.dart';
import 'package:bexly/core/constants/app_text_styles.dart';

class ForgotPasswordScreen extends HookConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final isLoading = useState(false);
    final emailSent = useState(false);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    final bexlyAuth = ref.watch(bexlyAuthProvider);

    Future<void> handleResetPassword() async {
      if (!formKey.currentState!.validate()) return;

      isLoading.value = true;
      try {
        await bexlyAuth.sendPasswordResetEmail(
          email: emailController.text.trim(),
        );

        emailSent.value = true;

        if (context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Email Sent'),
            description: const Text('Check your inbox for password reset instructions'),
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        if (context.mounted) {
          String errorMessage = 'Failed to send reset email';
          final error = e.toString();

          if (error.contains('user-not-found')) {
            errorMessage = 'No account found with this email';
          } else if (error.contains('invalid-email')) {
            errorMessage = 'Please enter a valid email address';
          } else if (error.contains('too-many-requests')) {
            errorMessage = 'Too many attempts. Please try again later';
          }

          toastification.show(
            context: context,
            title: const Text('Error'),
            description: Text(errorMessage),
            type: ToastificationType.error,
            style: ToastificationStyle.fillColored,
            autoCloseDuration: const Duration(seconds: 4),
          );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: emailSent.value
                ? _buildSuccessView(context)
                : Form(
                    key: formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.lock_reset_outlined,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const Gap(24),
                        Text(
                          'Forgot Password?',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(8),
                        Text(
                          'Enter your email and we\'ll send you instructions to reset your password',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const Gap(32),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => handleResetPassword(),
                          style: AppTextStyles.body3,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            isDense: true,
                            contentPadding: const EdgeInsets.fromLTRB(
                              0,
                              AppSpacing.spacing16,
                              0,
                              AppSpacing.spacing16,
                            ),
                            border: CustomInputBorder(
                              borderSide: const BorderSide(color: AppColors.neutral600),
                              borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                            ),
                            enabledBorder: CustomInputBorder(
                              borderSide: const BorderSide(color: AppColors.neutral600),
                              borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                            ),
                            focusedBorder: CustomInputBorder(
                              borderSide: const BorderSide(color: AppColors.purple),
                              borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                            ),
                            errorBorder: CustomInputBorder(
                              borderSide: const BorderSide(color: AppColors.red),
                              borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                            ),
                            focusedErrorBorder: CustomInputBorder(
                              borderSide: const BorderSide(color: AppColors.red),
                              borderRadius: BorderRadius.circular(AppSpacing.spacing8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const Gap(24),
                        FilledButton(
                          onPressed: isLoading.value ? null : handleResetPassword,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: isLoading.value
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Send Reset Link', style: TextStyle(fontSize: 16)),
                        ),
                        const Gap(16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              'Remember your password?',
                              style: AppTextStyles.body4,
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text('Sign In'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const Gap(24),
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const Gap(8),
        Text(
          'We\'ve sent password reset instructions to your email. Please check your inbox and follow the link to reset your password.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
        const Gap(32),
        FilledButton(
          onPressed: () => context.pop(),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Back to Sign In', style: TextStyle(fontSize: 16)),
        ),
        const Gap(16),
        Text(
          'Didn\'t receive the email? Check your spam folder or try again.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
