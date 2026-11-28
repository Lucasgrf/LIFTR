import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/errors/user_facing_message.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_card.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef SignUpResult = ({
  String? userId,
  bool hasSession,
  bool requiresEmailConfirmation,
});
typedef SignUpAction =
    Future<SignUpResult> Function({
      required String name,
      required String email,
      required String password,
      required String emailRedirectTo,
    });

final signUpActionProvider = Provider<SignUpAction>((ref) {
  return ({
    required String name,
    required String email,
    required String password,
    required String emailRedirectTo,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return (
        userId: null,
        hasSession: false,
        requiresEmailConfirmation: false,
      );
    }
    final authResponse = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
      emailRedirectTo: emailRedirectTo,
    );
    return (
      userId: authResponse.user?.id,
      hasSession: authResponse.session != null,
      requiresEmailConfirmation: authResponse.session == null,
    );
  };
});

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  String? _pendingConfirmationEmail;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();
      final result = await ref.read(signUpActionProvider)(
        name: name,
        email: email,
        password: _passwordController.text,
        emailRedirectTo: SupabaseConfig.authCallbackRedirectUrl,
      );
      if (!mounted) return;
      if (result.requiresEmailConfirmation) {
        if (result.userId != null) {
          ref.read(activeUserIdProvider.notifier).state = result.userId;
        }
        ref
            .read(userSettingsProvider.notifier)
            .resetForAccount(displayName: name);
        TextInput.finishAutofillContext();
        setState(() => _pendingConfirmationEmail = email);
        return;
      }
      syncActiveAuthSession(
        ref,
        isLoggedIn: result.hasSession,
        overrideUserId: result.userId,
      );
      ref
          .read(userSettingsProvider.notifier)
          .resetForAccount(displayName: name);
      TextInput.finishAutofillContext();
      context.go('/onboarding');
    } catch (e, st) {
      if (!mounted) return;
      context.showSnackBar(
        userFacingMessage(e, stackTrace: st, context: 'RegisterScreen._submit'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final spacing = context.appSpacing;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: ResponsiveContainer(
              child: _pendingConfirmationEmail != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: LiftrWordmark(),
                        ),
                        AppSpacing.verticalGap24,
                        AppCard(
                          padding: EdgeInsets.all(spacing.space20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Confirme seu e-mail',
                                style: context.textTheme.titleLarge,
                              ),
                              AppSpacing.verticalGap8,
                              Text(
                                'Enviamos um link de confirmação para $_pendingConfirmationEmail. Abra o link neste celular para ativar sua conta e entrar.',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                              AppSpacing.verticalGap20,
                              AppButton.primary(
                                label: 'Ir para o login',
                                onPressed: () => context.go('/login'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Form(
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
                            'Configure seu perfil em menos de 2 minutos.',
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),
                          AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppInput(
                                  label: 'Nome',
                                  hint: 'Como você quer ser chamado',
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.name],
                                  onFieldSubmitted: (_) =>
                                      _emailFocus.requestFocus(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Informe seu nome';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
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
                                  hint: 'Mínimo 6 caracteres',
                                  controller: _passwordController,
                                  focusNode: _passwordFocus,
                                  obscureText: true,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  onFieldSubmitted: (_) => _submit(),
                                  validator: (value) {
                                    if (value == null || value.length < 6) {
                                      return 'A senha deve ter ao menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          AppButton.primary(
                            label: 'Criar conta',
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/login'),
                              child: Text.rich(
                                TextSpan(
                                  text: 'Já tem conta? ',
                                  style: context.textTheme.bodyMedium?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Entrar',
                                      style: context.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
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
