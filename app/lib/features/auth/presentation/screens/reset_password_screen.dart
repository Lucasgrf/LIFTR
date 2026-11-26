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
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef PasswordUpdater = Future<void> Function(String newPassword);

final passwordUpdaterProvider = Provider<PasswordUpdater>((ref) {
  return (newPassword) async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  };
});

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(passwordUpdaterProvider)(_passwordController.text);
      TextInput.finishAutofillContext();
      if (!mounted) return;
      ref.read(passwordRecoveryPendingProvider.notifier).state = false;
      context.showSnackBar('Senha atualizada com sucesso.');
      final isLoggedIn = ref.read(authStateProvider);
      context.go(isLoggedIn ? '/' : '/login');
    } catch (e, st) {
      if (!mounted) return;
      context.showSnackBar(
        userFacingMessage(
          e,
          stackTrace: st,
          context: 'ResetPasswordScreen._submit',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _cancelRecovery() {
    if (_isLoading) return;
    ref.read(passwordRecoveryPendingProvider.notifier).state = false;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
                    AppSpacing.verticalGap12,
                    Text(
                      'Defina sua nova senha para voltar aos treinos.',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    AppSpacing.verticalGap32,
                    AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppInput(
                            label: 'Nova senha',
                            hint: 'Mínimo 6 caracteres',
                            controller: _passwordController,
                            focusNode: _passwordFocus,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) =>
                                _confirmFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Informe sua nova senha';
                              }
                              if (value.length < 6) {
                                return 'A senha deve ter ao menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          AppSpacing.verticalGap16,
                          AppInput(
                            label: 'Confirmar nova senha',
                            hint: 'Repita a nova senha',
                            controller: _confirmController,
                            focusNode: _confirmFocus,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.newPassword],
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirme sua nova senha';
                              }
                              if (value != _passwordController.text) {
                                return 'As senhas não coincidem';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.verticalGap24,
                    AppButton.primary(
                      label: 'Salvar nova senha',
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _submit,
                    ),
                    AppSpacing.verticalGap12,
                    AppButton.text(
                      label: 'Voltar ao login',
                      onPressed: _isLoading ? null : _cancelRecovery,
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
