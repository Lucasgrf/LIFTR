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
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
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

  void _toggleWarmup() {
    HapticFeedback.selectionClick();
    setState(() {
      _setType =
          _setType == SetType.warmup ? SetType.working : SetType.warmup;
    });
    widget.onToggleWarmup?.call();
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

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        weightKg: _weight,
        repsCompleted: _reps,
        rirActual: _rir,
        setType: _setType,
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
        fg = _isCompleted
            ? fitnessColors.progressUp
            : colors.textSecondary;
        break;
    }

    return Semantics(
      label: _setType == SetType.warmup
          ? 'Série de aquecimento. Toque para marcar como válida'
          : 'Série ${widget.setNumber}. Toque para alternar aquecimento',
      button: true,
      child: InkWell(
        onTap: _toggleWarmup,
        onLongPress: _toggleWarmup,
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(radius.small),
            ),
            child: Text(
              label,
              style: context.textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
                fontFeatures: AppTypography.tabularFeatures,
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

    return GestureDetector(
      onLongPress: _toggleWarmup,
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        margin: const EdgeInsets.only(bottom: 7),
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
        child: Row(
          children: [
            _buildBadge(context),
            const SizedBox(width: 6),

            // Weight Stepper
            Expanded(
              flex: 13,
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
            const SizedBox(width: 6),

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
              const SizedBox(width: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 6),
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

            const SizedBox(width: 6),

            // Check Button (48x48 touch target)
            Semantics(
              label: 'Marcar série ${widget.setNumber} como concluída',
              button: true,
              selected: isDone,
              child: InkWell(
                onTap: _isSaving ? null : _handleSave,
                onLongPress: isDone ? widget.onDelete : null,
                borderRadius: BorderRadius.circular(radius.medium),
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: Center(
                    child: AnimatedScale(
                      scale: isDone ? 1.03 : 1.0,
                      duration: disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      child: Container(
                        width: 44,
                        height: 44,
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
                                padding: const EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.check_rounded,
                                size: 22,
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
  });

  final String valueText;
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
      height: 45,
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
                width: 34,
                height: 45,
                child: Icon(
                  Icons.remove_rounded,
                  size: 18,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: onTapValue,
              child: Center(
                child: Text(
                  valueText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFeatures: AppTypography.tabularFeatures,
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
                width: 34,
                height: 45,
                child: Icon(
                  Icons.add_rounded,
                  size: 18,
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
