import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/theme/app_typography.dart';
import 'package:personal_fitness_os/core/theme/fitness_colors.dart';
import 'package:personal_fitness_os/features/workout_session/domain/entities/logged_set.dart';

class LoggedSetRow extends StatefulWidget {
  const LoggedSetRow({
    super.key,
    required this.setNumber,
    this.initialType = SetType.working,
    this.loggedSet,
    this.defaultWeight = 0.0,
    this.defaultReps = 10,
    this.defaultRir = 2,
    this.weightIncrement = 2.5,
    this.showRir = true,
    required this.onSave,
    this.onDelete,
    this.onToggleWarmup,
  });

  final int setNumber;
  final SetType initialType;
  final LoggedSet? loggedSet;
  final double defaultWeight;
  final int defaultReps;
  final int defaultRir;
  final double weightIncrement;
  final bool showRir;
  final Future<void> Function({
    required double weightKg,
    required int repsCompleted,
    int? rirActual,
    required SetType setType,
    List<DropSetEntry> dropSets,
    String? existingSetId,
  }) onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleWarmup;

  @override
  State<LoggedSetRow> createState() => _LoggedSetRowState();
}

class _LoggedSetRowState extends State<LoggedSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late double _weight;
  late int _reps;
  late int? _rir;
  late SetType _setType;
  late List<DropSetEntry> _dropSets;
  bool _isSaving = false;

  bool get _isCompleted => widget.loggedSet != null;

  @override
  void initState() {
    super.initState();
    _weight = widget.loggedSet?.weightKg ?? widget.defaultWeight;
    _reps = widget.loggedSet?.repsCompleted ?? widget.defaultReps;
    _weightController = TextEditingController(text: _formatWeight(_weight));
    _repsController = TextEditingController(text: _reps > 0 ? '$_reps' : '');
    _rir = widget.loggedSet?.rirActual ?? widget.defaultRir;
    _setType = widget.loggedSet?.setType ?? widget.initialType;
    _dropSets = List<DropSetEntry>.from(
      widget.loggedSet?.dropSets ??
          (_setType == SetType.dropSet
              ? [_createSuggestedDrop()]
              : const <DropSetEntry>[]),
    );
  }

  @override
  void didUpdateWidget(covariant LoggedSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loggedSet != widget.loggedSet && widget.loggedSet != null) {
      _weight = widget.loggedSet!.weightKg;
      _reps = widget.loggedSet!.repsCompleted;
      _weightController.text = _formatWeight(_weight);
      _repsController.text = '$_reps';
      _rir = widget.loggedSet!.rirActual;
      _setType = widget.loggedSet!.setType;
      _dropSets = List<DropSetEntry>.from(widget.loggedSet!.dropSets);
    } else if (widget.loggedSet == null &&
        oldWidget.initialType != widget.initialType) {
      _setType = widget.initialType;
      if (_setType == SetType.dropSet && _dropSets.isEmpty) {
        _dropSets = [_createSuggestedDrop()];
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  DropSetEntry _createSuggestedDrop({double? baseWeight}) {
    final sourceWeight = baseWeight ??
        (_dropSets.isNotEmpty ? _dropSets.last.weightKg : _weight);
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
      _weight = (_weight + delta).clamp(0.0, 999.0);
      _weightController.text = _formatWeight(_weight);
    });
  }

  void _stepReps(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _reps = (_reps + delta).clamp(0, 999);
      _repsController.text = '$_reps';
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
            _dropSets = [_createSuggestedDrop()];
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
          _dropSets = [_createSuggestedDrop()];
        }
      } else {
        _dropSets = [];
      }
    });
    widget.onToggleWarmup?.call();
  }

  Future<void> _showSetTypePicker() async {
    final colors = context.appColors;
    final radius = context.appRadius;
    final chosen = await showModalBottomSheet<SetType>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(radius.full),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tipo da série ${widget.setNumber}',
                style: ctx.textTheme.titleLarge),
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
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          decoration: const InputDecoration(),
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
      ),
    );
    controller.dispose();
    if (result != null) {
      onConfirm(result);
    }
  }

  Future<void> _handleSave() async {
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
        rirActual: _rir,
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
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

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
        bg = fitnessColors.progressDown.withValues(alpha: 0.16);
        fg = fitnessColors.progressDown;
        break;
      case SetType.myoRep:
        label = 'MYO';
        bg = fitnessColors.muscleShoulders.withValues(alpha: 0.16);
        fg = fitnessColors.muscleShoulders;
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
      child: InkWell(
        onTap: _cycleSetType,
        onLongPress: _showSetTypePicker,
        borderRadius: BorderRadius.circular(radius.small),
        child: AnimatedScale(
          scale: _setType == SetType.warmup ? 0.96 : 1.0,
          duration: disableAnimations
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 3),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;
    final radius = context.appRadius;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final isDone = _isCompleted;
    final isDropSet = _setType == SetType.dropSet;

    return GestureDetector(
      onLongPress: _showSetTypePicker,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        margin: const EdgeInsets.only(bottom: 7),
        decoration: BoxDecoration(
          color: isDone
              ? fitnessColors.progressUp.withValues(alpha: 0.08)
              : isDropSet
                  ? fitnessColors.progressDown.withValues(alpha: 0.04)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(radius.medium),
          border: Border.all(
            color: isDone
                ? fitnessColors.progressUp.withValues(alpha: 0.28)
                : isDropSet
                    ? fitnessColors.progressDown.withValues(alpha: 0.32)
                    : colors.border.withValues(alpha: 0.6),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildBadge(context),
                const SizedBox(width: 4),

                // Weight Stepper
                Expanded(
                  flex: 12,
                  child: _TactileStepper(
                    valueText: _formatWeight(_weight),
                    decrementLabel: 'Diminuir carga',
                    incrementLabel: 'Aumentar carga',
                    onDecrement: () => _stepWeight(-widget.weightIncrement),
                    onIncrement: () => _stepWeight(widget.weightIncrement),
                    onTapValue: () => _editNumericDialog(
                      title: 'Carga (kg)',
                      initialValue: _formatWeight(_weight),
                      decimal: true,
                      onConfirm: (val) {
                        final parsed = double.tryParse(
                          val.trim().replaceAll(',', '.'),
                        );
                        if (parsed != null && parsed >= 0) {
                          setState(() {
                            _weight = parsed.clamp(0.0, 999.0);
                            _weightController.text = _formatWeight(_weight);
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Reps Stepper
                Expanded(
                  flex: 10,
                  child: _TactileStepper(
                    valueText: '$_reps',
                    decrementLabel: 'Diminuir repetições',
                    incrementLabel: 'Aumentar repetições',
                    onDecrement: () => _stepReps(-1),
                    onIncrement: () => _stepReps(1),
                    onTapValue: () => _editNumericDialog(
                      title: 'Repetições',
                      initialValue: '$_reps',
                      decimal: false,
                      onConfirm: (val) {
                        final parsed = int.tryParse(val.trim());
                        if (parsed != null && parsed >= 0) {
                          setState(() {
                            _reps = parsed.clamp(0, 999);
                            _repsController.text = '$_reps';
                          });
                        }
                      },
                    ),
                  ),
                ),

                if (widget.showRir) ...[
                  const SizedBox(width: 4),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
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
                  ),
                ],

                const SizedBox(width: 4),

                // Check Button
                Semantics(
                  label: 'Marcar série ${widget.setNumber} como concluída',
                  button: true,
                  selected: isDone,
                  child: InkWell(
                    onTap: _isSaving ? null : _handleSave,
                    onLongPress: isDone ? widget.onDelete : null,
                    borderRadius: BorderRadius.circular(radius.medium),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedScale(
                          scale: isDone ? 1.03 : 1.0,
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isDone
                                  ? fitnessColors.progressUp
                                  : colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(radius.medium),
                              border: Border.all(
                                color: isDone
                                    ? fitnessColors.progressUp
                                    : colors.border,
                              ),
                            ),
                            child: _isSaving
                                ? Padding(
                                    padding: const EdgeInsets.all(10),
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
                  ),
                ),
              ],
            ),

            // Drop-set segments
            if (isDropSet) ...[
              const SizedBox(height: 6),
              for (var i = 0; i < _dropSets.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.subdirectory_arrow_right_rounded,
                              size: 14,
                              color: fitnessColors.progressDown,
                            ),
                            Text(
                              _dropSets.length > 1 ? 'D${i + 1}' : '',
                              style: context.textTheme.labelSmall?.copyWith(
                                color: fitnessColors.progressDown,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 12,
                        child: _TactileStepper(
                          height: 38,
                          valueText: _formatWeight(_dropSets[i].weightKg),
                          decrementLabel: 'Diminuir carga do drop ${i + 1}',
                          incrementLabel: 'Aumentar carga do drop ${i + 1}',
                          onDecrement: () =>
                              _stepDropWeight(i, -widget.weightIncrement),
                          onIncrement: () =>
                              _stepDropWeight(i, widget.weightIncrement),
                          onTapValue: () => _editNumericDialog(
                            title: 'Carga do drop (kg)',
                            initialValue: _formatWeight(_dropSets[i].weightKg),
                            decimal: true,
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
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 10,
                        child: _TactileStepper(
                          height: 38,
                          valueText: '+${_dropSets[i].repsCompleted}',
                          decrementLabel: 'Diminuir repetições do drop ${i + 1}',
                          incrementLabel: 'Aumentar repetições do drop ${i + 1}',
                          onDecrement: () => _stepDropReps(i, -1),
                          onIncrement: () => _stepDropReps(i, 1),
                          onTapValue: () => _editNumericDialog(
                            title: 'Repetições do drop',
                            initialValue: '${_dropSets[i].repsCompleted}',
                            decimal: false,
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
                        ),
                      ),
                      const SizedBox(width: 4),
                      Semantics(
                        label: 'Remover drop ${i + 1}',
                        button: true,
                        child: InkWell(
                          onTap: () => _removeDrop(i),
                          borderRadius: BorderRadius.circular(radius.small),
                          child: SizedBox(
                            width: 44,
                            height: 38,
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
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 38),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: _addAnotherDrop,
                    borderRadius: BorderRadius.circular(radius.small),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: fitnessColors.progressDown,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Outro drop',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: fitnessColors.progressDown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TactileStepper extends StatelessWidget {
  const _TactileStepper({
    required this.valueText,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
    required this.onTapValue,
    this.height = 44,
  });

  final String valueText;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onTapValue;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final radius = context.appRadius;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius.small),
      ),
      child: Row(
        children: [
          Semantics(
            label: decrementLabel,
            button: true,
            child: InkWell(
              onTap: onDecrement,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(radius.small),
              ),
              child: SizedBox(
                width: 26,
                height: height,
                child: Icon(
                  Icons.remove_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapValue,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      valueText,
                      maxLines: 1,
                      softWrap: false,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontSize: height < 42 ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            label: incrementLabel,
            button: true,
            child: InkWell(
              onTap: onIncrement,
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(radius.small),
              ),
              child: SizedBox(
                width: 26,
                height: height,
                child: Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
