import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/liftr_brand_mark.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      String? registeredUserId;
      var hasSession = false;
      if (SupabaseConfig.isConfigured) {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'name': _nameController.text.trim()},
        );
        registeredUserId = authResponse.user?.id;
        hasSession = authResponse.session != null;
      }
      if (!mounted) return;
      if (hasSession || !SupabaseConfig.isConfigured) {
        syncActiveAuthSession(
          ref,
          isLoggedIn: hasSession,
          overrideUserId: registeredUserId,
        );
      } else if (registeredUserId != null) {
        ref.read(activeUserIdProvider.notifier).state = registeredUserId;
      }
      ref.read(userSettingsProvider.notifier).resetForAccount(
            displayName: _nameController.text.trim(),
          );
      context.go('/onboarding');
    } catch (e) {
      if (!mounted) return;
      context.showSnackBar('Erro ao criar conta: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    const SizedBox(height: 10),
                    Text(
                      'Configure seu perfil em menos de 2 minutos.',
                      style: context.textTheme.bodyLarge?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Nome',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      style: context.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'Como você quer ser chamado',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe seu nome';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'E-mail',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: context.textTheme.bodyLarge,
                      decoration: const InputDecoration(
                        hintText: 'voce@exemplo.com',
                      ),
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
                    Text(
                      'Senha',
                      style: context.textTheme.labelMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      style: context.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'Mínimo 6 caracteres',
                        suffixIcon: Semantics(
                          label: _obscurePassword
                              ? 'Mostrar senha'
                              : 'Ocultar senha',
                          button: true,
                          child: IconButton(
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: colors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return 'A senha deve ter ao menos 6 caracteres';
                        }
                        return null;
                      },
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
