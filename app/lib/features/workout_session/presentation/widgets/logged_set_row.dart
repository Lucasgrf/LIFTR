import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_spacing.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/core/widgets/liftr_sheet_header.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

class LoggedSetRow extends StatefulWidget {
  const LoggedSetRow({
    super.key,
    required this.setNumber,
    this.initialType = SetType.working,
    this.loggedSet,
    this.defaultWeight = 0.0,
    this.defaultReps = 10,
    this.defaultDurationMinutes = 15,
    this.defaultRir = 2,
    this.weightIncrement = 2.5,
    this.showRir = true,
    this.isCardio = false,
    this.syncToken = 0,
    required this.onSave,
    this.onDelete,
    this.onToggleWarmup,
    this.onApplyToRemaining,
    this.onDraftChanged,
  });

  final int setNumber;
  final SetType initialType;
  final LoggedSet? loggedSet;
  final double defaultWeight;
  final int defaultReps;
  final int defaultDurationMinutes;
  final int defaultRir;
  final double weightIncrement;
  final bool showRir;
  final bool isCardio;
  final int syncToken;
  final Future<void> Function({
    required double weightKg,
    required int repsCompleted,
    int? durationSeconds,
    int? rirActual,
    required SetType setType,
    List<DropSetEntry> dropSets,
    String? existingSetId,
  }) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleWarmup;
  final void Function(double weightKg, int repsCompleted)? onApplyToRemaining;
  final void Function(double weightKg, int repsCompleted)? onDraftChanged;

  @override
  State<LoggedSetRow> createState() => _LoggedSetRowState();
}

class _LoggedSetRowState extends State<LoggedSetRow> {
  late double _weight;
  late int _reps;
  late int _durationMinutes;
  late int? _rir;
  late SetType _setType;
  List<DropSetEntry> _dropSets = <DropSetEntry>[];
  bool _userEditedWeight = false;
  bool _userEditedReps = false;
  bool _isSaving = false;

  bool get _isCompleted => widget.loggedSet != null;

  bool get _hasUnsavedEdits {
    final logged = widget.loggedSet;
    if (logged == null) return false;
    if (widget.isCardio) {
      return _durationMinutes != _resolveDurationMinutes();
    }
    return _weight != logged.weightKg ||
        _reps != logged.repsCompleted ||
        _setType != logged.setType ||
        !listEquals(_dropSets, logged.dropSets);
  }

  int _resolveDurationMinutes() {
    final logged = widget.loggedSet;
    if (logged != null) {
      if (logged.durationMinutes > 0) return logged.durationMinutes;
      if (logged.repsCompleted > 0) return logged.repsCompleted;
    }
    return widget.defaultDurationMinutes > 0
        ? widget.defaultDurationMinutes
        : 15;
  }

  @override
  void initState() {
    super.initState();
    _weight = widget.loggedSet?.weightKg ?? widget.defaultWeight;
    _reps = widget.loggedSet?.repsCompleted ?? widget.defaultReps;
    _durationMinutes = _resolveDurationMinutes();
    _rir = widget.loggedSet?.rirActual ?? widget.defaultRir;
    _setType = widget.loggedSet?.setType ?? widget.initialType;
    final existingDrops = widget.loggedSet?.dropSets;
    if (existingDrops != null && existingDrops.isNotEmpty) {
      _dropSets = List<DropSetEntry>.from(existingDrops);
    } else if (_setType == SetType.dropSet) {
      _dropSets = [_createSuggestedDrop(baseWeight: _weight, currentDrops: const [])];
    } else {
      _dropSets = <DropSetEntry>[];
    }
  }

  @override
  void didUpdateWidget(covariant LoggedSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loggedSet != widget.loggedSet && widget.loggedSet != null) {
      _weight = widget.loggedSet!.weightKg;
      _reps = widget.loggedSet!.repsCompleted;
      _durationMinutes = _resolveDurationMinutes();
      _rir = widget.loggedSet!.rirActual ?? widget.defaultRir;
      _setType = widget.loggedSet!.setType;
      _dropSets = List<DropSetEntry>.from(widget.loggedSet!.dropSets);
      _userEditedWeight = false;
      _userEditedReps = false;
    } else if (widget.loggedSet == null) {
      final forceSync = oldWidget.syncToken != widget.syncToken;
      if (forceSync) {
        _userEditedWeight = false;
        _userEditedReps = false;
      }
      if (oldWidget.initialType != widget.initialType) {
        _setType = widget.initialType;
        if (_setType == SetType.dropSet && _dropSets.isEmpty) {
          _dropSets = [_createSuggestedDrop(baseWeight: _weight)];
        }
      }
      if (!_userEditedWeight &&
          (forceSync || oldWidget.defaultWeight != widget.defaultWeight)) {
        _weight = widget.defaultWeight;
        if (_setType == SetType.dropSet &&
            _dropSets.length == 1 &&
            _dropSets.first.weightKg == 0 &&
            _weight > 0) {
          _dropSets = [_createSuggestedDrop(baseWeight: _weight, currentDrops: const [])];
        }
      }
      if (!_userEditedReps &&
          (forceSync || oldWidget.defaultReps != widget.defaultReps)) {
        _reps = widget.defaultReps;
      }
    }
  }

  DropSetEntry _createSuggestedDrop({
    double? baseWeight,
    List<DropSetEntry>? currentDrops,
  }) {
    final dropsList = currentDrops ?? _dropSets;
    final sourceWeight = baseWeight ??
        (dropsList.isNotEmpty ? dropsList.last.weightKg : _weight);
    final inc = widget.weightIncrement > 0 ? widget.weightIncrement : 2.5;
    final reduced = sourceWeight > 0
        ? ((sourceWeight * 0.75) / inc).round() * inc
        : 0.0;
    return DropSetEntry(
      weightKg: reduced.clamp(0.0, 999.0),
      repsCompleted: 3,
    );
  }

  String _formatWeight(double w) {
    if (w == w.toInt()) return w.toInt().toString();
    return w.toStringAsFixed(1);
  }

  void _stepWeight(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _userEditedWeight = true;
      _weight = (_weight + delta).clamp(0.0, 999.0);
    });
    widget.onDraftChanged?.call(_weight, _reps);
  }

  void _stepReps(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _userEditedReps = true;
      _reps = (_reps + delta).clamp(0, 999);
    });
    widget.onDraftChanged?.call(_weight, _reps);
  }

  void _stepDuration(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _durationMinutes = (_durationMinutes + delta).clamp(1, 300);
    });
  }

  void _cycleSetType() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_setType) {
        case SetType.working:
          _setType = SetType.warmup;
          break;
        case SetType.warmup:
          _setType = SetType.dropSet;
          if (_dropSets.isEmpty) {
            _dropSets = [_createSuggestedDrop(baseWeight: _weight, currentDrops: const [])];
          }
          break;
        case SetType.dropSet:
        case SetType.mobility:
        case SetType.rampUp:
        case SetType.myoRep:
          _setType = SetType.working;
          _dropSets = [];
          break;
      }
    });
    widget.onToggleWarmup?.call();
  }

  void _selectSetType(SetType nextType) {
    HapticFeedback.selectionClick();
    setState(() {
      _setType = nextType;
      if (nextType == SetType.dropSet) {
        if (_dropSets.isEmpty) {
          _dropSets = [_createSuggestedDrop(baseWeight: _weight, currentDrops: const [])];
        }
      } else {
        _dropSets = [];
      }
    });
    widget.onToggleWarmup?.call();
  }

  Future<void> _showSetTypePicker() async {
    final colors = context.appColors;
    final chosen = await showModalBottomSheet<SetType>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiftrSheetHeader(
              eyebrow: 'SÉRIE ${widget.setNumber}',
              title: 'Tipo da série ${widget.setNumber}',
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Série válida'),
              subtitle: const Text('Conta para progressão e volume'),
              trailing: _setType == SetType.working
                  ? Icon(Icons.check_rounded, color: colors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, SetType.working),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aquecimento (AQ)'),
              subtitle: const Text('Não entra na progressão nem no volume'),
              trailing: _setType == SetType.warmup
                  ? Icon(Icons.check_rounded, color: colors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, SetType.warmup),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Drop-set (DROP)'),
              subtitle: const Text('Redução de carga imediata após a série'),
              trailing: _setType == SetType.dropSet
                  ? Icon(Icons.check_rounded, color: colors.primary)
                  : null,
              onTap: () => Navigator.pop(ctx, SetType.dropSet),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && mounted) {
      _selectSetType(chosen);
    }
  }

  void _stepDropWeight(int index, double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = _dropSets[index];
      _dropSets[index] = current.copyWith(
        weightKg: (current.weightKg + delta).clamp(0.0, 999.0),
      );
    });
  }

  void _stepDropReps(int index, int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = _dropSets[index];
      _dropSets[index] = current.copyWith(
        repsCompleted: (current.repsCompleted + delta).clamp(1, 999),
      );
    });
  }

  void _addAnotherDrop() {
    HapticFeedback.lightImpact();
    setState(() {
      _setType = SetType.dropSet;
      _dropSets.add(_createSuggestedDrop());
    });
  }

  void _removeDrop(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _dropSets.removeAt(index);
      if (_dropSets.isEmpty) {
        _setType = SetType.working;
      }
    });
  }

  Future<void> _editNumericDialog({
    required String title,
    required String initialValue,
    required bool decimal,
    required ValueChanged<String> onConfirm,
    List<int>? quickRepsOptions,
    List<double>? quickWeightDeltas,
  }) async {
    final controller = TextEditingController(text: initialValue);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: initialValue.length,
    );
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        final radius = ctx.appRadius;
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                decoration: const InputDecoration(),
                onSubmitted: (v) => Navigator.pop(ctx, v),
              ),
              if (quickRepsOptions != null && quickRepsOptions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickRepsOptions.map((val) {
                    return ActionChip(
                      label: Text(
                        '$val',
                        style: ctx.textTheme.labelMedium?.copyWith(
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                      backgroundColor: colors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius.small),
                        side: BorderSide(color: colors.border),
                      ),
                      onPressed: () => Navigator.pop(ctx, '$val'),
                    );
                  }).toList(),
                ),
              ],
              if (quickWeightDeltas != null && quickWeightDeltas.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickWeightDeltas.map((delta) {
                    final sign = delta > 0 ? '+' : '';
                    final label = delta == delta.toInt()
                        ? '$sign${delta.toInt()} kg'
                        : '$sign${delta.toStringAsFixed(1).replaceAll('.', ',')} kg';
                    return ActionChip(
                      label: Text(
                        label,
                        style: ctx.textTheme.labelSmall?.copyWith(
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                      backgroundColor: colors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radius.small),
                        side: BorderSide(color: colors.border),
                      ),
                      onPressed: () {
                        final currentVal = double.tryParse(
                              controller.text.trim().replaceAll(',', '.'),
                            ) ??
                            0.0;
                        final nextVal = (currentVal + delta).clamp(0.0, 999.0);
                        controller.text = _formatWeight(nextVal);
                        controller.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: controller.text.length,
                        );
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null) {
      onConfirm(result);
    }
  }

  Future<void> _handleCheckPressed() async {
    if (_isSaving) return;
    if (_isCompleted && !_hasUnsavedEdits && widget.onDelete != null) {
      HapticFeedback.lightImpact();
      widget.onDelete!();
      return;
    }
    await _handleSave();
  }

  Future<void> _handleSave() async {
    if (widget.isCardio) {
      if (_durationMinutes <= 0) {
        context.showSnackBar(
          'Informe o tempo do cardio em minutos.',
          isError: true,
        );
        return;
      }
      HapticFeedback.mediumImpact();
      setState(() => _isSaving = true);
      try {
        await widget.onSave(
          weightKg: 0.0,
          repsCompleted: 0,
          durationSeconds: _durationMinutes * 60,
          rirActual: null,
          setType: SetType.working,
          dropSets: const <DropSetEntry>[],
          existingSetId: widget.loggedSet?.id,
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
      return;
    }

    if (_reps <= 0) {
      context.showSnackBar('Informe o número de repetições.', isError: true);
      return;
    }

    final validDrops = _setType == SetType.dropSet
        ? _dropSets.where((d) => d.repsCompleted > 0).toList()
        : const <DropSetEntry>[];

    if (_setType == SetType.dropSet && validDrops.isEmpty) {
      context.showSnackBar(
        'Informe as repetições do drop-set.',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        weightKg: _weight,
        repsCompleted: _reps,
        rirActual: widget.showRir ? _rir : widget.loggedSet?.rirActual,
        setType: _setType,
        dropSets: List<DropSetEntry>.unmodifiable(validDrops),
        existingSetId: widget.loggedSet?.id,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildBadge(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;

    final String label;
    final Color bg;
    final Color fg;

    switch (_setType) {
      case SetType.mobility:
        label = 'MOB';
        bg = fitnessColors.muscleCore.withValues(alpha: 0.16);
        fg = fitnessColors.muscleCore;
        break;
      case SetType.warmup:
        label = 'AQ';
        bg = fitnessColors.warmupTag.withValues(alpha: 0.16);
        fg = fitnessColors.warmupTag;
        break;
      case SetType.rampUp:
        label = 'REC';
        bg = fitnessColors.progressNeutral.withValues(alpha: 0.16);
        fg = fitnessColors.progressNeutral;
        break;
      case SetType.dropSet:
        label = 'DROP';
        bg = fitnessColors.dropSetTag.withValues(alpha: 0.16);
        fg = fitnessColors.dropSetTag;
        break;
      case SetType.myoRep:
        label = 'MYO';
        bg = colors.info.withValues(alpha: 0.16);
        fg = colors.info;
        break;
      case SetType.working:
        label = '${widget.setNumber}';
        bg = _isCompleted
            ? fitnessColors.progressUp.withValues(alpha: 0.18)
            : colors.surfaceElevated;
        fg = _isCompleted ? fitnessColors.progressUp : colors.textSecondary;
        break;
    }

    return Semantics(
      label: _setType == SetType.warmup
          ? 'Série de aquecimento. Toque para alternar tipo'
          : _setType == SetType.dropSet
              ? 'Série drop-set. Toque para alternar tipo'
              : 'Série ${widget.setNumber}. Toque para alternar aquecimento ou drop-set',
      button: true,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: _cycleSetType,
          onLongPress: _showSetTypePicker,
          borderRadius: BorderRadius.circular(radius.small),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 34,
                height: 34,
                padding: EdgeInsets.symmetric(horizontal: context.appSpacing.space4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(radius.small),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedActionsStrip(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 38),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!widget.isCardio && _setType != SetType.dropSet)
              Semantics(
                label: 'Adicionar drop-set na série ${widget.setNumber}',
                button: true,
                child: InkWell(
                  onTap: () => _selectSetType(SetType.dropSet),
                  borderRadius: BorderRadius.circular(radius.small),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: fitnessColors.dropSetTag.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(radius.small),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: fitnessColors.dropSetTag,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+ Drop-set',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: fitnessColors.dropSetTag,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_hasUnsavedEdits)
              Semantics(
                label: 'Salvar alteração na série ${widget.setNumber}',
                button: true,
                child: InkWell(
                  onTap: _isSaving ? null : _handleSave,
                  borderRadius: BorderRadius.circular(radius.small),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryMuted,
                          borderRadius: BorderRadius.circular(radius.small),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: colors.primaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Salvar alteração',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.primaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.isCardio && widget.onApplyToRemaining != null)
              Semantics(
                label: 'Aplicar carga e repetições às séries restantes',
                button: true,
                child: InkWell(
                  onTap: _isSaving
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onApplyToRemaining!(_weight, _reps);
                        },
                  borderRadius: BorderRadius.circular(radius.small),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(radius.small),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.copy_all_rounded,
                              size: 14,
                              color: colors.primaryLight,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Aplicar às restantes',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.labelSmall?.copyWith(
                                  color: colors.primaryLight,
                                  fontWeight: FontWeight.w600,
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
            if (widget.onDelete != null)
              Semantics(
                label: 'Desfazer série ${widget.setNumber}',
                button: true,
                child: InkWell(
                  onTap: _isSaving
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          widget.onDelete!();
                        },
                  borderRadius: BorderRadius.circular(radius.small),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    child: Center(
                      widthFactor: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(radius.small),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.undo_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Desfazer',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final isDone = _isCompleted;
    final hasPendingEdit = isDone && _hasUnsavedEdits;

    if (widget.isCardio) {
      final cardioBadge = Semantics(
        label: 'Bloco de cardio ${widget.setNumber}',
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isDone
                ? fitnessColors.progressUp.withValues(alpha: 0.18)
                : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(radius.small),
          ),
          child: Icon(
            Icons.directions_run_rounded,
            size: 18,
            color: isDone ? fitnessColors.progressUp : colors.textSecondary,
          ),
        ),
      );
      final cardioStepper = _TactileStepper(
        valueText: '$_durationMinutes min',
        valueLabel: 'Editar tempo de cardio: $_durationMinutes min',
        decrementLabel: 'Diminuir tempo de cardio',
        incrementLabel: 'Aumentar tempo de cardio',
        onDecrement: () => _stepDuration(-5),
        onIncrement: () => _stepDuration(5),
        onTapValue: () => _editNumericDialog(
          title: 'Tempo de cardio (min)',
          initialValue: '$_durationMinutes',
          decimal: false,
          quickRepsOptions: const [10, 15, 20, 30, 45],
          onConfirm: (val) {
            final parsed = int.tryParse(val.trim());
            if (parsed != null && parsed > 0) {
              setState(() {
                _durationMinutes = parsed.clamp(1, 300);
              });
            }
          },
        ),
      );
      final cardioCheckButton = Semantics(
        label: isDone && !hasPendingEdit
            ? 'Desfazer bloco de cardio ${widget.setNumber}'
            : 'Marcar bloco de cardio ${widget.setNumber} como concluído',
        button: true,
        selected: isDone,
        child: InkWell(
          onTap: _isSaving ? null : _handleCheckPressed,
          onLongPress: isDone ? widget.onDelete : null,
          borderRadius: BorderRadius.circular(radius.medium),
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDone
                      ? fitnessColors.progressUp
                      : colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(radius.medium),
                  border: Border.all(
                    color: isDone ? fitnessColors.progressUp : colors.border,
                  ),
                ),
                child: _isSaving
                    ? Padding(
                        padding: EdgeInsets.all(context.appSpacing.space8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.onPrimary,
                        ),
                      )
                    : Icon(
                        Icons.check_rounded,
                        size: 21,
                        color: isDone
                            ? fitnessColors.onSuccess
                            : colors.textTertiary,
                      ),
              ),
            ),
          ),
        ),
      );

      return Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: EdgeInsets.all(context.appSpacing.space8),
        margin: EdgeInsets.only(bottom: context.appSpacing.space8),
        decoration: BoxDecoration(
          color: isDone
              ? fitnessColors.progressUp.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(radius.medium),
          border: Border.all(
            color: isDone
                ? fitnessColors.progressUp.withValues(alpha: 0.28)
                : colors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 272.0) {
                  return Row(
                    children: [
                      cardioBadge,
                      AppSpacing.horizontalGap8,
                      Expanded(child: cardioStepper),
                      AppSpacing.horizontalGap8,
                      cardioCheckButton,
                    ],
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        cardioBadge,
                        AppSpacing.horizontalGap8,
                        Expanded(
                          child: Text(
                            'Bloco ${widget.setNumber}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                        AppSpacing.horizontalGap8,
                        cardioCheckButton,
                      ],
                    ),
                    AppSpacing.verticalGap8,
                    cardioStepper,
                  ],
                );
              },
            ),
            if (isDone) _buildCompletedActionsStrip(context),
          ],
        ),
      );
    }

    final isDropSet = _setType == SetType.dropSet;

    final weightStepper = _TactileStepper(
      valueText: _formatWeight(_weight),
      unitLabel: 'kg',
      valueLabel: 'Editar carga: ${_formatWeight(_weight)} kg',
      decrementLabel: 'Diminuir carga',
      incrementLabel: 'Aumentar carga',
      onDecrement: () => _stepWeight(-widget.weightIncrement),
      onIncrement: () => _stepWeight(widget.weightIncrement),
      onTapValue: () => _editNumericDialog(
        title: 'Carga (kg)',
        initialValue: _formatWeight(_weight),
        decimal: true,
        quickWeightDeltas: const [-5.0, -2.5, 2.5, 5.0],
        onConfirm: (val) {
          final parsed = double.tryParse(val.trim().replaceAll(',', '.'));
          if (parsed != null && parsed >= 0) {
            setState(() {
              _userEditedWeight = true;
              _weight = parsed.clamp(0.0, 999.0);
            });
            widget.onDraftChanged?.call(_weight, _reps);
          }
        },
      ),
    );

    final repsStepper = _TactileStepper(
      valueText: '$_reps',
      unitLabel: 'reps',
      valueLabel: 'Editar repetições: $_reps reps',
      decrementLabel: 'Diminuir repetições',
      incrementLabel: 'Aumentar repetições',
      onDecrement: () => _stepReps(-1),
      onIncrement: () => _stepReps(1),
      onTapValue: () => _editNumericDialog(
        title: 'Repetições',
        initialValue: '$_reps',
        decimal: false,
        quickRepsOptions: const [6, 8, 10, 12, 15],
        onConfirm: (val) {
          final parsed = int.tryParse(val.trim());
          if (parsed != null && parsed >= 0) {
            setState(() {
              _userEditedReps = true;
              _reps = parsed.clamp(0, 999);
            });
            widget.onDraftChanged?.call(_weight, _reps);
          }
        },
      ),
    );

    final rirSelector = Container(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.symmetric(horizontal: context.appSpacing.space8),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius.small),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _rir,
          isDense: true,
          dropdownColor: colors.surfaceElevated,
          style: context.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFeatures: AppTypography.tabularFeatures,
          ),
          items: [0, 1, 2, 3, 4].map((val) {
            return DropdownMenuItem<int?>(
              value: val,
              child: Text('RIR $val'),
            );
          }).toList(),
          onChanged: (v) => setState(() => _rir = v),
        ),
      ),
    );

    final checkButton = Semantics(
      label: hasPendingEdit
          ? 'Atualizar série ${widget.setNumber}'
          : isDone
              ? 'Desfazer série ${widget.setNumber}'
              : 'Marcar série ${widget.setNumber} como concluída',
      button: true,
      selected: isDone,
      child: InkWell(
        onTap: _isSaving ? null : _handleCheckPressed,
        onLongPress: isDone ? widget.onDelete : null,
        borderRadius: BorderRadius.circular(radius.medium),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasPendingEdit
                    ? colors.primaryMuted
                    : isDone
                        ? fitnessColors.progressUp
                        : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(radius.medium),
                border: Border.all(
                  color: hasPendingEdit
                      ? colors.primary
                      : isDone
                          ? fitnessColors.progressUp
                          : colors.border,
                ),
              ),
              child: _isSaving
                  ? Padding(
                      padding: EdgeInsets.all(context.appSpacing.space8),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.check_rounded,
                      size: 21,
                      color: hasPendingEdit
                          ? colors.primaryLight
                          : isDone
                              ? fitnessColors.onSuccess
                              : colors.textTertiary,
                    ),
            ),
          ),
        ),
      ),
    );

    return GestureDetector(
      onLongPress: _showSetTypePicker,
      excludeFromSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: EdgeInsets.all(context.appSpacing.space8),
        margin: EdgeInsets.only(bottom: context.appSpacing.space8),
        decoration: BoxDecoration(
          color: isDone
              ? fitnessColors.progressUp.withValues(alpha: 0.08)
              : isDropSet
                  ? fitnessColors.dropSetTag.withValues(alpha: 0.05)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(radius.medium),
          border: Border.all(
            color: isDone
                ? fitnessColors.progressUp.withValues(alpha: 0.28)
                : isDropSet
                    ? fitnessColors.dropSetTag.withValues(alpha: 0.34)
                    : colors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wideBreakpoint = widget.showRir ? 520.0 : 448.0;
                if (constraints.maxWidth >= wideBreakpoint) {
                  return Row(
                    children: [
                      _buildBadge(context),
                      AppSpacing.horizontalGap8,
                      Expanded(flex: 12, child: weightStepper),
                      AppSpacing.horizontalGap8,
                      Expanded(flex: 10, child: repsStepper),
                      if (widget.showRir) ...[
                        AppSpacing.horizontalGap8,
                        rirSelector,
                      ],
                      AppSpacing.horizontalGap8,
                      checkButton,
                    ],
                  );
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _buildBadge(context),
                        AppSpacing.horizontalGap8,
                        Expanded(child: weightStepper),
                      ],
                    ),
                    AppSpacing.verticalGap8,
                    Row(
                      children: [
                        Expanded(child: repsStepper),
                        AppSpacing.horizontalGap8,
                        checkButton,
                      ],
                    ),
                    if (widget.showRir) ...[
                      AppSpacing.verticalGap8,
                      Align(
                        alignment: Alignment.centerLeft,
                        child: rirSelector,
                      ),
                    ],
                  ],
                );
              },
            ),

            // Drop-set sub-widget anchored directly below this set row
            if (isDropSet)
              Container(
                margin: EdgeInsets.only(
                  top: context.appSpacing.space8,
                  left: context.appSpacing.space4,
                ),
                padding: EdgeInsets.all(context.appSpacing.space8),
                decoration: BoxDecoration(
                  color: fitnessColors.dropSetTag.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(radius.small),
                  border: Border(
                    left: BorderSide(
                      color: fitnessColors.dropSetTag,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: context.appSpacing.space8,
                      runSpacing: context.appSpacing.space4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 13,
                              color: fitnessColors.dropSetTag,
                            ),
                            AppSpacing.horizontalGap4,
                            Text(
                              'DROP-SET',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: fitnessColors.dropSetTag,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          label: 'Adicionar outro drop',
                          button: true,
                          excludeSemantics: true,
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: _addAnotherDrop,
                              borderRadius:
                                  BorderRadius.circular(radius.small),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                child: Center(
                                  widthFactor: 1,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: context.appSpacing.space8,
                                      vertical: context.appSpacing.space4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          size: 14,
                                          color: fitnessColors.dropSetTag,
                                        ),
                                        AppSpacing.horizontalGap4,
                                        Flexible(
                                          child: Text(
                                            'Outro drop',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: context.textTheme.labelSmall
                                                ?.copyWith(
                                              color: fitnessColors.dropSetTag,
                                              fontWeight: FontWeight.w700,
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
                        ),
                      ],
                    ),
                    for (var i = 0; i < _dropSets.length; i++)
                      Padding(
                        padding: EdgeInsets.only(top: context.appSpacing.space8),
                        child: LayoutBuilder(
                          builder: (context, dropConstraints) {
                            final dIndicator = SizedBox(
                              width: 28,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.subdirectory_arrow_right_rounded,
                                    size: 13,
                                    color: fitnessColors.dropSetTag,
                                  ),
                                  Text(
                                    _dropSets.length > 1 ? 'D${i + 1}' : '',
                                    style:
                                        context.textTheme.labelSmall?.copyWith(
                                      color: fitnessColors.dropSetTag,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            final dropWeightStepper = _TactileStepper(
                              valueText: _formatWeight(_dropSets[i].weightKg),
                              unitLabel: 'kg',
                              valueLabel:
                                  'Editar carga do drop ${i + 1}: ${_formatWeight(_dropSets[i].weightKg)} kg',
                              decrementLabel:
                                  'Diminuir carga do drop ${i + 1}',
                              incrementLabel:
                                  'Aumentar carga do drop ${i + 1}',
                              onDecrement: () =>
                                  _stepDropWeight(i, -widget.weightIncrement),
                              onIncrement: () =>
                                  _stepDropWeight(i, widget.weightIncrement),
                              onTapValue: () => _editNumericDialog(
                                title: 'Carga do drop (kg)',
                                initialValue:
                                    _formatWeight(_dropSets[i].weightKg),
                                decimal: true,
                                quickWeightDeltas: const [-5.0, -2.5, 2.5, 5.0],
                                onConfirm: (val) {
                                  final parsed = double.tryParse(
                                    val.trim().replaceAll(',', '.'),
                                  );
                                  if (parsed != null && parsed >= 0) {
                                    setState(() {
                                      _dropSets[i] = _dropSets[i].copyWith(
                                        weightKg: parsed.clamp(0.0, 999.0),
                                      );
                                    });
                                  }
                                },
                              ),
                            );
                            final dropRepsStepper = _TactileStepper(
                              valueText: '+${_dropSets[i].repsCompleted}',
                              unitLabel: 'reps',
                              valueLabel:
                                  'Editar repetições do drop ${i + 1}: ${_dropSets[i].repsCompleted} reps',
                              decrementLabel:
                                  'Diminuir repetições do drop ${i + 1}',
                              incrementLabel:
                                  'Aumentar repetições do drop ${i + 1}',
                              onDecrement: () => _stepDropReps(i, -1),
                              onIncrement: () => _stepDropReps(i, 1),
                              onTapValue: () => _editNumericDialog(
                                title: 'Repetições do drop',
                                initialValue: '${_dropSets[i].repsCompleted}',
                                decimal: false,
                                quickRepsOptions: const [3, 5, 6, 8, 10],
                                onConfirm: (val) {
                                  final parsed = int.tryParse(val.trim());
                                  if (parsed != null && parsed > 0) {
                                    setState(() {
                                      _dropSets[i] = _dropSets[i].copyWith(
                                        repsCompleted: parsed.clamp(1, 999),
                                      );
                                    });
                                  }
                                },
                              ),
                            );
                            final removeButton = Semantics(
                              label: 'Remover drop ${i + 1}',
                              button: true,
                              child: Material(
                                type: MaterialType.transparency,
                                child: InkWell(
                                  onTap: () => _removeDrop(i),
                                  borderRadius:
                                      BorderRadius.circular(radius.small),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 16,
                                      color: colors.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                            );

                            if (dropConstraints.maxWidth >= 420.0) {
                              return Row(
                                children: [
                                  dIndicator,
                                  AppSpacing.horizontalGap8,
                                  Expanded(flex: 12, child: dropWeightStepper),
                                  AppSpacing.horizontalGap8,
                                  Expanded(flex: 10, child: dropRepsStepper),
                                  AppSpacing.horizontalGap8,
                                  removeButton,
                                ],
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    dIndicator,
                                    AppSpacing.horizontalGap4,
                                    Expanded(child: dropWeightStepper),
                                  ],
                                ),
                                AppSpacing.verticalGap8,
                                Row(
                                  children: [
                                    Expanded(child: dropRepsStepper),
                                    AppSpacing.horizontalGap8,
                                    removeButton,
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

            if (isDone)
              _buildCompletedActionsStrip(context)
            else if (!widget.isCardio &&
                widget.onApplyToRemaining != null &&
                (_userEditedWeight || _userEditedReps))
              Padding(
                padding: EdgeInsets.only(
                  top: context.appSpacing.space8,
                  left: context.appSpacing.space12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    label: 'Aplicar carga e repetições às séries restantes',
                    button: true,
                    child: InkWell(
                      onTap: _isSaving
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              widget.onApplyToRemaining!(_weight, _reps);
                            },
                      borderRadius: BorderRadius.circular(radius.small),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: context.appSpacing.space8,
                              vertical: context.appSpacing.space8,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(radius.small),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_all_rounded,
                                  size: 14,
                                  color: colors.primaryLight,
                                ),
                                AppSpacing.horizontalGap4,
                                Flexible(
                                  child: Text(
                                    'Aplicar às restantes',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        context.textTheme.labelSmall?.copyWith(
                                      color: colors.primaryLight,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TactileStepper extends StatelessWidget {
  const _TactileStepper({
    required this.valueText,
    this.unitLabel,
    this.valueLabel,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapValue,
  });

  final String valueText;
  final String? unitLabel;
  final String? valueLabel;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTapValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius.small),
      ),
      child: Row(
        children: [
          Semantics(
            label: decrementLabel,
            button: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onDecrement,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(radius.small),
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          AppSpacing.horizontalGap8,
          Expanded(
            child: Semantics(
              label: valueLabel ??
                  'Editar $valueText${unitLabel != null ? ' $unitLabel' : ''}',
              button: true,
              excludeSemantics: true,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTapValue,
                  borderRadius: BorderRadius.circular(radius.small),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.appSpacing.space4,
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                valueText,
                                maxLines: 1,
                                softWrap: false,
                                style: context.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.textPrimary,
                                  fontFeatures: AppTypography.tabularFeatures,
                                ),
                              ),
                              if (unitLabel != null) ...[
                                AppSpacing.horizontalGap4,
                                Text(
                                  unitLabel!,
                                  maxLines: 1,
                                  softWrap: false,
                                  style:
                                      context.textTheme.labelSmall?.copyWith(
                                    color: colors.textTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          AppSpacing.horizontalGap8,
          Semantics(
            label: incrementLabel,
            button: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onIncrement,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(radius.small),
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
