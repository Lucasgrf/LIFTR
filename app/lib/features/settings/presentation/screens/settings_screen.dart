import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:personal_fitness_os/core/constants/supabase_config.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/network/connectivity_providers.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/theme/theme_provider.dart';
import 'package:personal_fitness_os/core/update/app_update_providers.dart';
import 'package:personal_fitness_os/core/update/app_update_service.dart';
import 'package:personal_fitness_os/core/update/app_update_widgets.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';
import 'package:personal_fitness_os/features/workout_session/data/repositories/session_repository_impl.dart';
import 'package:personal_fitness_os/features/workout_session/presentation/providers/session_providers.dart';
import 'package:personal_fitness_os/routing/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(appUpdateProvider.notifier).loadInstalledVersion());
    });
  }

  String _formatRestDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')} (${seconds}s)';
  }

  String _updateRowValue(AppUpdateState updateState) {
    if (updateState.phase == AppUpdatePhase.checking) {
      return 'Verificando...';
    }
    if (updateState.availableUpdate != null) {
      return 'v${updateState.availableUpdate!.versionName} disponível';
    }
    if (updateState.installedVersion != null) {
      return updateState.installedVersion!.formattedLabel;
    }
    return 'Verificar';
  }

  String _updateRowSubtitle(AppUpdateState updateState) {
    if (updateState.phase == AppUpdatePhase.checking) {
      return 'Consultando GitHub Releases';
    }
    if (updateState.availableUpdate != null) {
      return 'Nova versão pronta para instalar';
    }
    if (updateState.phase == AppUpdatePhase.upToDate) {
      return 'Você está na versão mais recente';
    }
    return 'Toque para verificar atualizações';
  }

  Future<void> _handleUpdateCheck(
    BuildContext context,
    AppUpdateState current,
  ) async {
    if (current.phase == AppUpdatePhase.downloading ||
        current.phase == AppUpdatePhase.verifying ||
        current.phase == AppUpdatePhase.permissionRequired ||
        current.phase == AppUpdatePhase.installing) {
      await showAppUpdateSheet(context);
      return;
    }

    final result = await ref.read(appUpdateProvider.notifier).checkManually();
    if (!context.mounted) return;

    switch (result.status) {
      case AppUpdateCheckStatus.available:
        await showAppUpdateSheet(context);
        break;
      case AppUpdateCheckStatus.upToDate:
        context.showSnackBar('Você já está na versão mais recente.');
        break;
      case AppUpdateCheckStatus.unsupported:
        context.showSnackBar(
          'Atualizações in-app disponíveis apenas no Android.',
        );
        break;
      case AppUpdateCheckStatus.failed:
        context.showSnackBar(
          result.errorMessage ?? 'Não foi possível verificar atualizações.',
          isError: true,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final settings = ref.watch(userSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final simulatedOffline = ref.watch(simulatedOfflineProvider);
    final isOfflineState = ref.watch(isOfflineModeProvider);
    final pendingCount = ref.watch(pendingSyncCountProvider);
    final updateState = ref.watch(appUpdateProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Top Header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(
                  bottom: BorderSide(color: colors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Semantics(
                    label: 'Voltar',
                    button: true,
                    child: IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Configurações',
                      style: context.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Grouped Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                children: [
                  ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionHeader('TREINO & EQUIPAMENTOS'),
                        _SettingsCardGroup(
                          children: [
                            _SettingsRow(
                              label: 'Descanso padrão',
                              value: _formatRestDuration(
                                settings.defaultRestSeconds,
                              ),
                              onTap: () => _showRestDurationPicker(
                                context,
                                ref,
                                settings.defaultRestSeconds,
                              ),
                            ),
                            _SettingsRow(
                              label: 'Barra',
                              value:
                                  '+${settings.barbellIncrementKg.toStringAsFixed(1).replaceAll('.', ',')} kg',
                              onTap: () => _showIncrementPicker(
                                context,
                                title: 'Incremento — Barra',
                                current: settings.barbellIncrementKg,
                                onSelect: (v) => ref
                                    .read(userSettingsProvider.notifier)
                                    .setEquipmentIncrement(barbell: v),
                              ),
                            ),
                            _SettingsRow(
                              label: 'Halter',
                              value:
                                  '+${settings.dumbbellIncrementKg.toStringAsFixed(1).replaceAll('.', ',')} kg',
                              onTap: () => _showIncrementPicker(
                                context,
                                title: 'Incremento — Halter',
                                current: settings.dumbbellIncrementKg,
                                onSelect: (v) => ref
                                    .read(userSettingsProvider.notifier)
                                    .setEquipmentIncrement(dumbbell: v),
                              ),
                            ),
                            _SettingsRow(
                              label: 'Máquina / Polia',
                              value:
                                  '+${settings.machineIncrementKg.toStringAsFixed(1).replaceAll('.', ',')} kg',
                              onTap: () => _showIncrementPicker(
                                context,
                                title: 'Incremento — Máquina / Polia',
                                current: settings.machineIncrementKg,
                                onSelect: (v) => ref
                                    .read(userSettingsProvider.notifier)
                                    .setEquipmentIncrement(machine: v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        const _SectionHeader('WHATSAPP'),
                        _SettingsCardGroup(
                          children: [
                            _SettingsRow(
                              label: 'Vínculo',
                              value: settings.whatsappConnected
                                  ? 'Conectado'
                                  : 'Não conectado',
                              subtitle: settings.whatsappConnected
                                  ? settings.whatsappMaskedPhone
                                  : 'Toque para vincular número',
                              valueColor: settings.whatsappConnected
                                  ? fitnessColors.progressUp
                                  : colors.textTertiary,
                              onTap: () => ref
                                  .read(userSettingsProvider.notifier)
                                  .setWhatsappConnected(
                                    !settings.whatsappConnected,
                                  ),
                            ),
                            _SettingsRow(
                              label: 'Relatório semanal',
                              value:
                                  '${settings.weeklyReportDay} · ${settings.weeklyReportTime}',
                              onTap: () => _showReportSchedulePicker(
                                context,
                                ref,
                                settings,
                              ),
                            ),
                            _SettingsToggleRow(
                              label: 'Horário silencioso',
                              subtitle: settings.quietHoursRange,
                              value: settings.quietHoursEnabled,
                              onChanged: (val) => ref
                                  .read(userSettingsProvider.notifier)
                                  .setQuietHoursEnabled(val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        const _SectionHeader('SINCRONIZAÇÃO OFFLINE & DADOS'),
                        _SettingsCardGroup(
                          children: [
                            _SettingsToggleRow(
                              label: 'Simular modo offline',
                              value: simulatedOffline,
                              activeColor: colors.warning,
                              onChanged: (val) => ref
                                  .read(simulatedOfflineProvider.notifier)
                                  .state = val,
                            ),
                            _SettingsRow(
                              label: 'Status local',
                              value: isOfflineState
                                  ? (pendingCount > 0
                                      ? 'Offline · $pendingCount ${pendingCount == 1 ? 'pendência' : 'pendências'}'
                                      : 'Offline · Salvo localmente')
                                  : (pendingCount > 0
                                      ? 'Online · $pendingCount para sincronizar'
                                      : 'Online · Tudo sincronizado'),
                              valueColor: isOfflineState || pendingCount > 0
                                  ? colors.warning
                                  : fitnessColors.progressUp,
                              showChevron: !isOfflineState && pendingCount > 0,
                              onTap: (!isOfflineState && pendingCount > 0)
                                  ? () async {
                                      final repo = ref.read(
                                        sessionRepositoryProvider,
                                      );
                                      if (repo is SessionRepositoryImpl) {
                                        final synced = await repo
                                            .syncPendingOperations();
                                        if (context.mounted) {
                                          context.showSnackBar(
                                            synced
                                                ? 'Sincronização concluída!'
                                                : 'Não foi possível sincronizar agora.',
                                            isError: !synced,
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                            _SettingsRow(
                              label: 'Tema',
                              value: _themeLabel(themeMode),
                              onTap: () =>
                                  _showThemePicker(context, ref, themeMode),
                            ),
                            _SettingsRow(
                              label: 'Exportar meus dados',
                              value: 'CSV / JSON',
                              onTap: () =>
                                  _showExportModal(context, settings),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        const _SectionHeader('CONTA'),
                        _SettingsCardGroup(
                          children: [
                            _SettingsRow(
                              label: 'Meu Perfil',
                              value: 'Foto, dados e objetivo',
                              onTap: () => context.push('/profile'),
                            ),
                            _SettingsRow(
                              label: 'Atualizações do app',
                              value: _updateRowValue(updateState),
                              subtitle: _updateRowSubtitle(updateState),
                              valueColor: updateState.availableUpdate != null
                                  ? colors.primaryLight
                                  : null,
                              onTap: () =>
                                  _handleUpdateCheck(context, updateState),
                            ),
                            _SettingsRow(
                              label: 'Sair da conta',
                              labelColor: colors.danger,
                              value: '',
                              showChevron: false,
                              onTap: () => _confirmLogout(context, ref),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'O acompanhamento diário de dieta e peso acontece pelo WhatsApp.',
                          style: context.textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Escuro (Padrão)';
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  void _showRestDurationPicker(
    BuildContext context,
    WidgetRef ref,
    int currentSeconds,
  ) {
    const options = [60, 90, 120, 150, 180, 240];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LiftrSheetHeader(
                eyebrow: 'SESSÃO DE TREINO',
                title: 'Descanso padrão entre séries',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((val) {
                  final selected = currentSeconds == val;
                  return ChoiceChip(
                    label: Text(_formatRestDuration(val)),
                    selected: selected,
                    selectedColor: colors.primaryMuted,
                    onSelected: (_) {
                      ref
                          .read(userSettingsProvider.notifier)
                          .setDefaultRestSeconds(val);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showIncrementPicker(
    BuildContext context, {
    required String title,
    required double current,
    required ValueChanged<double> onSelect,
  }) {
    const options = [0.5, 1.0, 1.25, 2.0, 2.5, 5.0];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiftrSheetHeader(
                eyebrow: 'PROGRESSÃO DE CARGA',
                title: title,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((val) {
                  final selected = (current - val).abs() < 0.01;
                  return ChoiceChip(
                    label: Text(
                      '+${val.toStringAsFixed(val % 1 == 0 ? 1 : 2).replaceAll('.', ',')} kg',
                    ),
                    selected: selected,
                    selectedColor: colors.primaryMuted,
                    onSelected: (_) {
                      onSelect(val);
                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportSchedulePicker(
    BuildContext context,
    WidgetRef ref,
    UserSettingsState settings,
  ) {
    const schedules = [
      ('Domingo', '19:00'),
      ('Domingo', '09:00'),
      ('Segunda-feira', '08:00'),
      ('Sexta-feira', '18:00'),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LiftrSheetHeader(
                eyebrow: 'WHATSAPP COACH',
                title: 'Relatório semanal',
              ),
              const SizedBox(height: 12),
              ...schedules.map((item) {
                final selected =
                    settings.weeklyReportDay == item.$1 &&
                    settings.weeklyReportTime == item.$2;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${item.$1} · ${item.$2}'),
                  trailing: selected
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(userSettingsProvider.notifier)
                        .setWeeklyReportSchedule(item.$1, item.$2);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LiftrSheetHeader(
                eyebrow: 'PREFERÊNCIAS',
                title: 'Aparência do app',
              ),
              const SizedBox(height: 12),
              for (final mode in [
                ThemeMode.dark,
                ThemeMode.light,
                ThemeMode.system,
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_themeLabel(mode)),
                  trailing: currentMode == mode
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _showExportModal(BuildContext context, UserSettingsState settings) {
    final payload = const JsonEncoder.withIndent('  ').convert({
      'app': 'LIFTR',
      'exported_at': DateTime.now().toIso8601String(),
      'profile': {
        'name': settings.displayName,
        'weight_kg': settings.weightKg,
        'height_cm': settings.heightCm,
        'age': settings.age,
        'goal': settings.goal.name,
        'calories_target': settings.estimatedDailyCalories,
        'protein_target_g': settings.estimatedDailyProteinGrams,
      },
      'training': {
        'default_rest_seconds': settings.defaultRestSeconds,
      },
      'increments': {
        'barbell_kg': settings.barbellIncrementKg,
        'dumbbell_kg': settings.dumbbellIncrementKg,
        'machine_kg': settings.machineIncrementKg,
      },
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.appColors;
        final radius = ctx.appRadius;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LiftrSheetHeader(
                eyebrow: 'BACKUP PORTÁTIL',
                title: 'Exportar dados',
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(radius.medium),
                  border: Border.all(color: colors.border),
                ),
                child: SelectableText(
                  payload,
                  style: ctx.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              AppButton.primary(
                label: 'Copiar JSON',
                icon: Icons.copy_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload));
                  Navigator.pop(ctx);
                  context.showSnackBar('Dados copiados para a área de transferência');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final colors = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Seus treinos locais continuam salvos no aparelho.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (SupabaseConfig.isConfigured) {
        await Supabase.instance.client.auth.signOut();
      }
      ref.read(authStateProvider.notifier).state = false;
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(title, style: AppTypography.eyebrow(context)),
    );
  }
}

class _SettingsCardGroup extends StatelessWidget {
  const _SettingsCardGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(radius.large),
        border: Border.all(color: colors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius.large),
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.labelColor,
    this.showChevron = true,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final Color? labelColor;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: labelColor ?? colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: valueColor ?? colors.textSecondary,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colors.textTertiary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.activeColor,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: colors.textTertiary,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: activeColor ?? colors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
