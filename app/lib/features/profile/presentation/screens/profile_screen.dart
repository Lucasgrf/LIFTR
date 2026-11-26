import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/utils/pt_br_number_utils.dart';
import 'package:personal_fitness_os/core/widgets/app_button.dart';
import 'package:personal_fitness_os/core/widgets/app_input.dart';
import 'package:personal_fitness_os/core/widgets/liftr_badge.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/core/widgets/responsive_container.dart';
import 'package:personal_fitness_os/features/profile/presentation/providers/profile_providers.dart';
import 'package:personal_fitness_os/features/settings/presentation/providers/settings_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final radius = context.appRadius;
    final settings = ref.watch(userSettingsProvider);
    final profileState = ref.watch(profileControllerProvider);

    final displayName = (settings.displayName?.trim().isNotEmpty ?? false)
        ? settings.displayName!.trim()
        : 'Atleta LIFTR';

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
                      'Perfil',
                      style: context.textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Semantics(
                    label: 'Abrir configurações',
                    button: true,
                    child: IconButton(
                      onPressed: () => context.push('/settings'),
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      icon: Icon(
                        Icons.settings_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                children: [
                  ResponsiveContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar & Identity Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(radius.xl),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              Semantics(
                                label: 'Alterar foto de perfil',
                                button: true,
                                container: true,
                                child: InkWell(
                                  onTap: profileState.isUploadingAvatar
                                      ? null
                                      : () => _showAvatarSourceSheet(
                                            context,
                                            ref,
                                            hasAvatar: settings.avatarUrl != null &&
                                                settings.avatarUrl!.isNotEmpty,
                                          ),
                                  borderRadius: BorderRadius.circular(999),
                                  child: ExcludeSemantics(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        _ProfileAvatarCircle(
                                          avatarUrl: settings.avatarUrl,
                                          storagePath: settings.avatarStoragePath,
                                          displayName: displayName,
                                          size: 92,
                                        ),
                                        if (profileState.isUploadingAvatar)
                                          Positioned.fill(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: colors.background
                                                    .withValues(alpha: 0.65),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: colors.primary,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colors.surface,
                                                width: 2,
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.camera_alt_rounded,
                                              size: 16,
                                              color: colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: () => _showEditNameDialog(
                                  context,
                                  ref,
                                  displayName,
                                ),
                                borderRadius:
                                    BorderRadius.circular(radius.small),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          displayName,
                                          style: context.textTheme.headlineSmall,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.edit_rounded,
                                        size: 16,
                                        color: colors.textTertiary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (profileState.email != null &&
                                  profileState.email!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  profileState.email!,
                                  style: context.textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              LiftrBadge(
                                label:
                                    '${settings.goal.label} · ${settings.experience.label}',
                                tone: LiftrBadgeTone.brand,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: Text(
                            'DADOS CORPORAIS & OBJETIVO',
                            style: AppTypography.eyebrow(context),
                          ),
                        ),
                        _ProfileCardGroup(
                          children: [
                            _ProfileRow(
                              label: 'Dados corporais',
                              value:
                                  '${formatPtBrDecimal(settings.weightKg, trimTrailingZero: false)} kg · ${settings.heightCm} cm · ${settings.age} anos',
                              subtitle: settings.bodyFatPercent != null
                                  ? 'Sexo ${settings.biologicalSex} · ${formatPtBrDecimal(settings.bodyFatPercent!, trimTrailingZero: false)}% gordura'
                                  : 'Sexo ${settings.biologicalSex}',
                              onTap: () => _showBodyDataSheet(context, settings),
                            ),
                            _ProfileRow(
                              label: 'Objetivo atual',
                              value: settings.goal.label,
                              subtitle: settings.goal.weeklyRateTargetLabel,
                              onTap: () =>
                                  _showGoalPicker(context, ref, settings),
                            ),
                            _ProfileRow(
                              label: 'Experiência',
                              value: settings.experience.label,
                              onTap: () =>
                                  _showExperiencePicker(context, ref, settings),
                            ),
                            _ProfileRow(
                              label: 'Atividade diária',
                              value: settings.activityLevel.label,
                              onTap: () =>
                                  _showActivityPicker(context, ref, settings),
                            ),
                            _ProfileRow(
                              label: 'Metas calculadas',
                              value:
                                  '${settings.estimatedDailyCalories} kcal · ${settings.estimatedDailyProteinGrams} g prot',
                              subtitle:
                                  'Acompanhamento diário feito pelo WhatsApp',
                              showChevron: false,
                            ),
                          ],
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

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 900,
      imageQuality: 85,
    );
    if (picked == null) return;

    final ok = await ref
        .read(profileControllerProvider.notifier)
        .uploadAvatar(picked.path);
    if (!context.mounted) return;
    if (ok) {
      context.showSnackBar('Foto de perfil atualizada!');
    } else {
      final err = ref.read(profileControllerProvider).errorMessage;
      context.showSnackBar(
        err ?? 'Erro ao atualizar foto de perfil.',
        isError: true,
      );
    }
  }

  void _showAvatarSourceSheet(
    BuildContext context,
    WidgetRef ref, {
    required bool hasAvatar,
  }) {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LiftrSheetHeader(
              eyebrow: 'ATLETA',
              title: 'Foto de perfil',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.camera_alt_rounded, color: colors.primary),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.photo_library_rounded, color: colors.primary),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(context, ref, ImageSource.gallery);
              },
            ),
            if (hasAvatar)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline_rounded, color: colors.danger),
                title: Text(
                  'Remover foto',
                  style: context.textTheme.bodyMedium?.copyWith(color: colors.danger),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(profileControllerProvider.notifier).removeAvatar();
                  context.showSnackBar('Foto removida.');
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final updated = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(
        initialName: currentName == 'Atleta LIFTR' ? '' : currentName,
      ),
    );
    if (updated != null && updated.trim().isNotEmpty) {
      await ref
          .read(profileControllerProvider.notifier)
          .updateDisplayName(updated);
    }
  }

  void _showBodyDataSheet(
    BuildContext context,
    UserSettingsState settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BodyDataSheet(initialSettings: settings),
    );
  }

  void _showGoalPicker(
    BuildContext context,
    WidgetRef ref,
    UserSettingsState settings,
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
                eyebrow: 'METAS & NUTRIÇÃO',
                title: 'Objetivo atual',
              ),
              const SizedBox(height: 14),
              ...UserGoal.values.map((goal) {
                final selected = settings.goal == goal;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(goal.label, style: ctx.textTheme.titleMedium),
                  subtitle: Text(
                    goal.subtitle,
                    style: ctx.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    ref.read(userSettingsProvider.notifier).setGoal(goal);
                    ref
                        .read(profileControllerProvider.notifier)
                        .syncSettingsToRemote();
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

  void _showExperiencePicker(
    BuildContext context,
    WidgetRef ref,
    UserSettingsState settings,
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
                eyebrow: 'HISTÓRICO DE TREINO',
                title: 'Experiência',
              ),
              const SizedBox(height: 14),
              ...UserExperience.values.map((exp) {
                final selected = settings.experience == exp;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(exp.label, style: ctx.textTheme.titleMedium),
                  subtitle: Text(
                    exp.subtitle,
                    style: ctx.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    ref.read(userSettingsProvider.notifier).setExperience(exp);
                    ref
                        .read(profileControllerProvider.notifier)
                        .syncSettingsToRemote();
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

  void _showActivityPicker(
    BuildContext context,
    WidgetRef ref,
    UserSettingsState settings,
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
                eyebrow: 'GASTO ENERGÉTICO',
                title: 'Atividade diária',
              ),
              const SizedBox(height: 14),
              ...ActivityLevel.values.map((lvl) {
                final selected = settings.activityLevel == lvl;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(lvl.label, style: ctx.textTheme.titleMedium),
                  subtitle: Text(
                    lvl.subtitle,
                    style: ctx.textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: selected
                      ? Icon(Icons.check_rounded, color: colors.primary)
                      : null,
                  onTap: () {
                    ref
                        .read(userSettingsProvider.notifier)
                        .setActivityLevel(lvl);
                    ref
                        .read(profileControllerProvider.notifier)
                        .syncSettingsToRemote();
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
}

class _ProfileAvatarCircle extends StatelessWidget {
  const _ProfileAvatarCircle({
    required this.avatarUrl,
    required this.storagePath,
    required this.displayName,
    required this.size,
  });

  final String? avatarUrl;
  final String? storagePath;
  final String displayName;
  final double size;

  Widget _fallback(BuildContext context) {
    final colors = context.appColors;
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (parts.isNotEmpty ? parts.first[0].toUpperCase() : 'L');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.primaryMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: context.textTheme.headlineMedium?.copyWith(
          color: colors.primaryLight,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) {
      return _fallback(context);
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ClipOval(
        child: Container(
          width: size,
          height: size,
          color: colors.surfaceElevated,
          child: CachedNetworkImage(
            imageUrl: url,
            cacheKey: (storagePath != null && storagePath!.isNotEmpty)
                ? storagePath
                : url,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, _) => _fallback(context),
            errorWidget: (_, _, _) => _fallback(context),
          ),
        ),
      );
    }

    final file = File(url);
    if (file.existsSync()) {
      return ClipOval(
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return _fallback(context);
  }
}

class _ProfileCardGroup extends StatelessWidget {
  const _ProfileCardGroup({required this.children});

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

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.label,
    required this.value,
    this.subtitle,
    this.showChevron = true,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
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
                    color: colors.textSecondary,
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

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seu nome'),
      content: AppInput(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        hint: 'Como quer ser chamado',
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _BodyDataSheet extends ConsumerStatefulWidget {
  const _BodyDataSheet({required this.initialSettings});

  final UserSettingsState initialSettings;

  @override
  ConsumerState<_BodyDataSheet> createState() => _BodyDataSheetState();
}

class _BodyDataSheetState extends ConsumerState<_BodyDataSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _bodyFatCtrl;
  late String _sex;

  @override
  void initState() {
    super.initState();
    final s = widget.initialSettings;
    _weightCtrl = TextEditingController(
      text: formatPtBrDecimal(s.weightKg, trimTrailingZero: false),
    );
    _heightCtrl = TextEditingController(text: '${s.heightCm}');
    _ageCtrl = TextEditingController(text: '${s.age}');
    _bodyFatCtrl = TextEditingController(
      text: s.bodyFatPercent != null
          ? formatPtBrDecimal(s.bodyFatPercent!, trimTrailingZero: false)
          : '',
    );
    _sex = s.biologicalSex;
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _bodyFatCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final w = parsePtBrDouble(_weightCtrl.text);
    final h = int.tryParse(_heightCtrl.text.trim());
    final a = int.tryParse(_ageCtrl.text.trim());
    final bfRaw = _bodyFatCtrl.text.trim();
    final bf = bfRaw.isEmpty ? null : parsePtBrDouble(bfRaw);

    ref.read(userSettingsProvider.notifier).updateBodyData(
          biologicalSex: _sex,
          weightKg: w,
          heightCm: h,
          age: a,
          bodyFatPercent: bf,
          clearBodyFat: bfRaw.isEmpty,
        );
    ref.read(profileControllerProvider.notifier).syncSettingsToRemote();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final spacing = context.appSpacing;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          spacing.space20,
          spacing.space20,
          spacing.space20,
          bottomInset + spacing.space24,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dados corporais', style: context.textTheme.titleLarge),
              AppSpacing.verticalGap12,
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('Masculino'),
                    selected: _sex == 'M',
                    onSelected: (_) => setState(() => _sex = 'M'),
                  ),
                  AppSpacing.horizontalGap8,
                  ChoiceChip(
                    label: const Text('Feminino'),
                    selected: _sex == 'F',
                    onSelected: (_) => setState(() => _sex = 'F'),
                  ),
                ],
              ),
              AppSpacing.verticalGap12,
              AppInput(
                label: 'Peso (kg)',
                hint: 'Ex: 78,5',
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [PtBrDecimalInputFormatter(maxDecimalDigits: 1)],
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final parsed = parsePtBrDouble(v);
                  if (parsed == null || parsed < 20 || parsed > 400) {
                    return 'Informe um peso entre 20 e 400 kg';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalGap12,
              AppInput(
                label: 'Altura (cm)',
                hint: 'Ex: 178',
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed < 100 || parsed > 250) {
                    return 'Informe uma altura entre 100 e 250 cm';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalGap12,
              AppInput(
                label: 'Idade (anos)',
                hint: 'Ex: 27',
                controller: _ageCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed < 12 || parsed > 100) {
                    return 'Informe uma idade entre 12 e 100 anos';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalGap12,
              AppInput(
                label: '% de gordura (opcional)',
                hint: 'Ex: 15,0',
                controller: _bodyFatCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [PtBrDecimalInputFormatter(maxDecimalDigits: 1)],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) return null;
                  final parsed = parsePtBrDouble(trimmed);
                  if (parsed == null || parsed < 3 || parsed > 60) {
                    return 'Informe entre 3% e 60%';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalGap20,
              AppButton.primary(
                label: 'Salvar',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
