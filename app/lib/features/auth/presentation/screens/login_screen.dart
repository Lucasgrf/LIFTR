import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/errors/failures.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/network_info.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/profile/presentation/providers/profile_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef PasswordResetSender = Future<void> Function(String email);

final passwordResetSenderProvider = Provider<PasswordResetSender>((ref) {
  return (email) async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: SupabaseConfig.passwordResetRedirectUrl,
    );
  };
});

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        sendReset: ref.read(passwordResetSenderProvider),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? signedInUserId;
      if (SupabaseConfig.isConfigured) {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        signedInUserId = response.user?.id;
      }
      if (!mounted) return;
      TextInput.finishAutofillContext();
      syncActiveAuthSession(
        ref,
        isLoggedIn: true,
        overrideUserId: signedInUserId,
      );
      unawaited(ref.read(profileControllerProvider.notifier).loadProfile());
      context.go('/');
    } catch (e, st) {
      if (!mounted) return;
      context.showSnackBar(
        userFacingMessage(e, stackTrace: st, context: 'LoginScreen._submit'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final spacing = context.appSpacing;
    final recoveryError = ref.watch(passwordRecoveryErrorProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ResponsiveContainer(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: LiftrWordmark(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Treine hoje. O resto acontece no WhatsApp.',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    if (recoveryError != null) ...[
                      AppCard(
                        variant: AppCardVariant.accented,
                        accentColor: colors.warning,
                        padding: EdgeInsets.all(spacing.space16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              recoveryError,
                              style: context.textTheme.bodyMedium?.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                            AppSpacing.verticalGap8,
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: () {
                                  ref
                                      .read(passwordRecoveryErrorProvider
                                          .notifier)
                                      .state = null;
                                  _showForgotPasswordDialog();
                                },
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(48, 48),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                                child: Text(
                                  'Solicitar novo link',
                                  style: context.textTheme.labelLarge?.copyWith(
                                    color: colors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.verticalGap16,
                    ],
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            label: 'E-mail',
                            hint: 'voce@exemplo.com',
                            controller: _emailController,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            onFieldSubmitted: (_) =>
                                _passwordFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Informe seu e-mail';
                              }
                              if (!value.contains('@')) {
                                return 'Informe um e-mail válido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppInput(
                            label: 'Senha',
                            hint: '••••••••',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe sua senha';
                              }
                              if (value.length < 6) {
                                return 'Mínimo de 6 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            _isLoading ? null : _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: Text(
                          'Esqueci minha senha',
                          style: context.textTheme.labelMedium?.copyWith(
                            color: colors.primaryLight,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton.primary(
                      label: 'Entrar',
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text.rich(
                          TextSpan(
                            text: 'Ainda não tem conta? ',
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                            children: [
                              TextSpan(
                                text: 'Criar conta',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(radius.medium),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.offline_bolt_rounded,
                            size: 18,
                            color: colors.primaryLight,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '100% offline-first · Seus treinos ficam salvos localmente no aparelho.',
                              style: context.textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({
    required this.initialEmail,
    required this.sendReset,
  });

  final String initialEmail;
  final PasswordResetSender sendReset;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);
  bool _isSubmitting = false;
  bool _sent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isTransientDeliveryError(Object error) {
    if (error is NetworkFailure ||
        error is SocketException ||
        error is TimeoutException ||
        isNetworkError(error)) {
      return true;
    }
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      return error.statusCode == '429' || msg.contains('rate limit');
    }
    return false;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await widget.sendReset(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _sent = true;
      });
    } catch (e, st) {
      appErrorLogger(
        e,
        stackTrace: st,
        context: 'ForgotPasswordDialog._submit',
      );
      if (!mounted) return;
      if (_isTransientDeliveryError(e)) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = userFacingMessage(
            e,
            stackTrace: st,
            context: 'ForgotPasswordDialog._submit',
            logError: false,
          );
        });
      } else {
        setState(() {
          _isSubmitting = false;
          _sent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      title: const Text('Redefinir senha'),
      content: _sent
          ? Text(
              'Se houver uma conta com esse e-mail, enviaremos um link para redefinir sua senha.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            )
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Informe o e-mail da sua conta para receber o link de recuperação.',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppInput(
                    label: 'E-mail',
                    hint: 'voce@exemplo.com',
                    controller: _emailController,
                    enabled: !_isSubmitting,
                    autofocus: widget.initialEmail.isEmpty,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    errorText: _errorMessage,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      if (!value.contains('@')) {
                        return 'Informe um e-mail válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
      actions: _sent
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Fechar'),
              ),
            ]
          : [
              TextButton(
                onPressed:
                    _isSubmitting ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: _isSubmitting ? null : _submit,
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text(_isSubmitting ? 'Enviando...' : 'Enviar link'),
              ),
            ],
    );
  }
}
