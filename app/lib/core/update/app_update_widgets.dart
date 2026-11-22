import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/update/app_update_info.dart';
import 'package:personal_fitness_os/core/update/app_update_providers.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';

class AppUpdateBanner extends StatelessWidget {
  const AppUpdateBanner({
    super.key,
    required this.updateInfo,
    required this.onUpdateTap,
    required this.onDismiss,
  });

  final AppUpdateInfo updateInfo;
  final VoidCallback onUpdateTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: colors.primaryMuted,
        border: Border(
          bottom: BorderSide(
            color: colors.primary.withValues(alpha: 0.28),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.system_update_rounded,
            size: 16,
            color: colors.primaryLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nova versão v${updateInfo.versionName} disponível',
              style: context.textTheme.labelSmall?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: AppTypography.tabularFeatures,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: 'Atualizar aplicativo',
            button: true,
            child: InkWell(
              onTap: onUpdateTap,
              borderRadius: BorderRadius.circular(radius.small),
              child: Container(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                child: Text(
                  'Atualizar',
                  style: context.textTheme.labelSmall?.copyWith(
                    color: colors.primaryLight,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: 'Ocultar aviso de atualização',
            button: true,
            child: InkWell(
              onTap: onDismiss,
              child: SizedBox(
                width: 48,
                height: 44,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: colors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAppUpdateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const AppUpdateSheet(),
  );
}

class AppUpdateSheet extends ConsumerStatefulWidget {
  const AppUpdateSheet({super.key});

  @override
  ConsumerState<AppUpdateSheet> createState() => _AppUpdateSheetState();
}

class _AppUpdateSheetState extends ConsumerState<AppUpdateSheet>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final updateState = ref.read(appUpdateProvider);
      if (updateState.phase == AppUpdatePhase.permissionRequired) {
        unawaited(
          ref.read(appUpdateProvider.notifier).retryInstallDownloadedApk(),
        );
      }
    }
  }

  String _formatBytes(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final updateState = ref.watch(appUpdateProvider);
    final notifier = ref.read(appUpdateProvider.notifier);
    final update = updateState.availableUpdate;

    if (update == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Atualizações do app', style: context.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Nenhuma nova versão disponível no momento.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppButton.secondary(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    final installedLabel = updateState.installedVersion?.formattedLabel ?? '--';
    final remoteLabel = update.buildNumber > 0
        ? 'v${update.versionName} (build ${update.buildNumber})'
        : 'v${update.versionName}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiftrSheetHeader(
            eyebrow: 'Atualização do app',
            title: 'Nova versão do LIFTR',
            subtitle: '$remoteLabel · ${update.formattedSize}',
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryMuted,
                borderRadius: BorderRadius.circular(radius.small),
              ),
              child: Icon(
                Icons.system_update_rounded,
                size: 20,
                color: colors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Versão instalada: $installedLabel',
            style: context.textTheme.bodySmall?.copyWith(
              color: colors.textTertiary,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
          if (update.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              constraints: const BoxConstraints(maxHeight: 160),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(radius.medium),
                border: Border.all(color: colors.border),
              ),
              child: SingleChildScrollView(
                child: Text(
                  update.releaseNotes,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (updateState.phase == AppUpdatePhase.downloading) ...[
            LinearProgressIndicator(
              value: updateState.progress,
              backgroundColor: colors.surfaceSubtle,
              color: colors.primary,
              borderRadius: BorderRadius.circular(radius.full),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              updateState.totalBytes > 0
                  ? 'Baixando ${_formatBytes(updateState.receivedBytes)} de ${_formatBytes(updateState.totalBytes)}...'
                  : 'Baixando atualização...',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontFeatures: AppTypography.tabularFeatures,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            AppButton.secondary(
              label: 'Cancelar',
              onPressed: notifier.cancelDownload,
            ),
          ] else if (updateState.phase == AppUpdatePhase.verifying) ...[
            LinearProgressIndicator(
              backgroundColor: colors.surfaceSubtle,
              color: colors.primary,
              borderRadius: BorderRadius.circular(radius.full),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              'Verificando integridade SHA-256...',
              style: context.textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ] else if (updateState.phase ==
              AppUpdatePhase.permissionRequired) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius.medium),
                border: Border.all(
                  color: colors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Permita que o LIFTR instale atualizações nas configurações do Android. Ao voltar, a instalação continuará automaticamente.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppButton.primary(
              label: 'Permitir instalação',
              icon: Icons.security_rounded,
              onPressed: notifier.openInstallPermissionSettings,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Já permiti, instalar agora',
              onPressed: notifier.retryInstallDownloadedApk,
            ),
          ] else if (updateState.phase == AppUpdatePhase.installing) ...[
            Text(
              'Instalador do Android aberto. Confirme a atualização para concluir.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            AppButton.primary(
              label: 'Abrir instalador novamente',
              icon: Icons.install_mobile_rounded,
              onPressed: notifier.retryInstallDownloadedApk,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else if (updateState.phase == AppUpdatePhase.error) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radius.medium),
                border: Border.all(
                  color: colors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                updateState.errorMessage ?? 'Falha ao atualizar o app.',
                style: context.textTheme.bodySmall?.copyWith(
                  color: colors.danger,
                ),
              ),
            ),
            const SizedBox(height: 14),
            AppButton.primary(
              label: 'Tentar novamente',
              icon: Icons.refresh_rounded,
              onPressed: notifier.downloadAndInstall,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Fechar',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ] else ...[
            AppButton.primary(
              label: 'Atualizar agora',
              icon: Icons.download_rounded,
              onPressed: notifier.downloadAndInstall,
            ),
            const SizedBox(height: 10),
            AppButton.secondary(
              label: 'Depois',
              onPressed: () {
                notifier.dismissBanner();
                Navigator.of(context).pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}
