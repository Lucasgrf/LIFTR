import 'package:flutter/material.dart';
import 'package:personal_fitness_os/core/constants/app_constants.dart';
import 'package:personal_fitness_os/core/theme/app_colors.dart';
import 'package:personal_fitness_os/core/theme/app_radius.dart';
import 'package:personal_fitness_os/core/extensions/context_extensions.dart';
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
    required this.onSave,
    this.onDelete,
  });

  final int setNumber;
  final SetType initialType;
  final LoggedSet? loggedSet;
  final double defaultWeight;
  final int defaultReps;
  final int defaultRir;
  final Future<void> Function({
    required double weightKg,
    required int repsCompleted,
    int? rirActual,
    required SetType setType,
  }) onSave;
  final VoidCallback? onDelete;

  @override
  State<LoggedSetRow> createState() => _LoggedSetRowState();
}

class _LoggedSetRowState extends State<LoggedSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;
  late int? _rir;
  late SetType _setType;
  bool _isSaving = false;

  bool get _isCompleted => widget.loggedSet != null;

  @override
  void initState() {
    super.initState();
    final weight = widget.loggedSet?.weightKg ?? widget.defaultWeight;
    final reps = widget.loggedSet?.repsCompleted ?? widget.defaultReps;
    _weightController = TextEditingController(
      text: weight > 0 ? (weight % 1 == 0 ? weight.toInt().toString() : weight.toString()) : '',
    );
    _repsController = TextEditingController(
      text: reps > 0 ? reps.toString() : '',
    );
    _rir = widget.loggedSet?.rirActual ?? widget.defaultRir;
    _setType = widget.loggedSet?.setType ?? widget.initialType;
  }

  @override
  void didUpdateWidget(covariant LoggedSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loggedSet != widget.loggedSet && widget.loggedSet != null) {
      final weight = widget.loggedSet!.weightKg;
      final reps = widget.loggedSet!.repsCompleted;
      _weightController.text =
          weight % 1 == 0 ? weight.toInt().toString() : weight.toString();
      _repsController.text = reps.toString();
      _rir = widget.loggedSet!.rirActual;
      _setType = widget.loggedSet!.setType;
    }
  }

  @override
  void dispose() {
    _weightController.dispose;
    _repsController.dispose;
    super.dispose();
  }

  Future<void> _handleSave() async {
    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0.0;
    final reps = int.tryParse(_repsController.text.trim()) ?? 0;

    if (reps <= 0) {
      context.showSnackBar('Informe o número de repetições.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        weightKg: weight,
        repsCompleted: reps,
        rirActual: _rir,
        setType: _setType,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildBadge(BuildContext context) {
    String label;
    Color bg;
    Color fg;

    switch (_setType) {
      case SetType.mobility:
        label = 'MOB';
        bg = context.fitnessColors.muscleCore.withOpacity(0.2);
        fg = context.fitnessColors.muscleCore;
        break;
      case SetType.warmup:
        label = 'AQ';
        bg = context.fitnessColors.progressMaintain.withOpacity(0.2);
        fg = context.fitnessColors.progressMaintain;
        break;
      case SetType.rampUp:
        label = 'REC';
        bg = context.fitnessColors.progressNeutral.withOpacity(0.2);
        fg = context.fitnessColors.progressNeutral;
        break;
      case SetType.dropSet:
        label = 'DROP';
        bg = context.fitnessColors.progressDown.withOpacity(0.2);
        fg = context.fitnessColors.progressDown;
        break;
      case SetType.myoRep:
        label = 'MYO';
        bg = context.fitnessColors.muscleShoulders.withOpacity(0.2);
        fg = context.fitnessColors.muscleShoulders;
        break;
      case SetType.working:
        label = '${widget.setNumber}';
        bg = _isCompleted
            ? context.fitnessColors.progressUp.withOpacity(0.2)
            : context.appColors.surfaceVariant;
        fg = _isCompleted
            ? context.fitnessColors.progressUp
            : context.appColors.textPrimary;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.appRadius.small),
      ),
      child: Text(
        label,
        style: context.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fitnessColors = context.fitnessColors;

    final isDone = _isCompleted;
    final rowBg = isDone ? fitnessColors.progressUp.withOpacity(0.08) : Colors.transparent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(context.appRadius.small),
        border: Border.all(
          color: isDone ? fitnessColors.progressUp.withOpacity(0.3) : colors.border,
        ),
      ),
      child: Row(
        children: [
          // Badge
          _buildBadge(context),
          const SizedBox(width: 12),

          // Weight Input
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  hintText: '0 kg',
                  hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(color: colors.textTertiary, fontSize: 11),
                  filled: true,
                  fillColor: colors.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reps Input
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _repsController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  hintText: 'reps',
                  hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
                  suffixText: 'rep',
                  suffixStyle: TextStyle(color: colors.textTertiary, fontSize: 11),
                  filled: true,
                  fillColor: colors.surfaceVariant.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // RIR Dropdown
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int?>(
                  value: _rir,
                  isDense: true,
                  isExpanded: true,
                  alignment: Alignment.center,
                  dropdownColor: colors.surfaceElevated,
                  style: context.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                  hint: Text(
                    'RIR',
                    style: TextStyle(color: colors.textTertiary, fontSize: 11),
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
          ),
          const SizedBox(width: 10),

          // Check Button (Log / Completed toggle)
          InkWell(
            onTap: _isSaving ? null : _handleSave,
            borderRadius: BorderRadius.circular(context.appRadius.small),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDone
                    ? fitnessColors.progressUp
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(context.appRadius.small),
              ),
              child: _isSaving
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: isDone ? Colors.white : colors.textTertiary,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
