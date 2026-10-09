import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/journal_entry.dart';
import 'package:break_free/core/models/urge_event.dart';
import 'package:break_free/core/providers/habit_provider.dart';
import 'package:break_free/core/providers/journal_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class JournalEntryEditorScreen extends StatefulWidget {
  const JournalEntryEditorScreen({super.key, this.existing});

  final JournalEntry? existing;

  @override
  State<JournalEntryEditorScreen> createState() => _JournalEntryEditorScreenState();
}

class _JournalEntryEditorScreenState extends State<JournalEntryEditorScreen> {
  late final TextEditingController _noteController;
  late double _mood;
  late double _urge;
  late bool _isRelapse;
  String? _habitId;
  String? _trigger;
  String? _coping;
  bool _saving = false;

  static const _copingOptions = [
    'Breathe',
    'Move',
    'Distract',
    'Walk',
    'Call someone',
    'Urge surfing',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _noteController = TextEditingController(text: e?.note ?? '');
    _mood = e?.moodRating ?? 3.0;
    _urge = e?.urgeIntensity ?? 0.0;
    _isRelapse = e?.isRelapse ?? false;
    _habitId = e?.habitId;
    _trigger = e?.triggersIdentified.isNotEmpty == true ? e!.triggersIdentified.first : null;
    _coping = e?.copingMethod;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final journal = context.read<JournalProvider>();
    final triggers = _trigger == null ? <String>[] : [_trigger!];
    try {
      if (widget.existing == null) {
        await journal.create(
          note: _noteController.text,
          moodRating: _mood,
          urgeIntensity: _urge,
          triggers: triggers,
          isRelapse: _isRelapse,
          habitId: _habitId,
          copingMethod: _coping,
        );
      } else {
        await journal.update(
          widget.existing!.copyWith(
            note: _noteController.text.trim(),
            moodRating: _mood,
            urgeIntensity: _urge,
            triggersIdentified: triggers,
            isRelapse: _isRelapse,
            habitId: _habitId,
            copingMethod: _coping,
            clearHabitId: _habitId == null,
            clearCopingMethod: _coping == null,
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save entry. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit reflection' : 'Today\'s reflection'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.huge),
        children: [
          const BfSectionLabel('How are you feeling?'),
          const SizedBox(height: BfSpacing.sm),
          Text(_moodLabel(_mood), style: Theme.of(context).textTheme.headlineSmall),
          Slider(
            value: _mood,
            min: 1,
            max: 5,
            divisions: 4,
            label: _mood.round().toString(),
            onChanged: (v) => setState(() => _mood = v),
          ),
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('What triggered you?'),
          const SizedBox(height: BfSpacing.sm),
          Wrap(
            spacing: BfSpacing.xs,
            runSpacing: BfSpacing.xs,
            children: [
              for (final t in UrgeTrigger.values)
                FilterChip(
                  label: Text(t.label),
                  selected: _trigger == t.label,
                  onSelected: (selected) => setState(() => _trigger = selected ? t.label : null),
                ),
            ],
          ),
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('What helped?'),
          const SizedBox(height: BfSpacing.sm),
          Wrap(
            spacing: BfSpacing.xs,
            runSpacing: BfSpacing.xs,
            children: [
              for (final c in _copingOptions)
                FilterChip(
                  label: Text(c),
                  selected: _coping == c,
                  onSelected: (selected) => setState(() => _coping = selected ? c : null),
                ),
            ],
          ),
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('Urge intensity'),
          const SizedBox(height: BfSpacing.xs),
          Text(
            _urge == 0 ? 'None noted' : '${_urge.round()} / 10',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Slider(
            value: _urge,
            min: 0,
            max: 10,
            divisions: 10,
            label: _urge == 0 ? 'None' : _urge.round().toString(),
            onChanged: (v) => setState(() => _urge = v),
          ),
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('Note'),
          const SizedBox(height: BfSpacing.sm),
          TextField(
            controller: _noteController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Optional. What do you want to remember about today?',
              alignLabelWithHint: true,
            ),
          ),
          if (habits.isNotEmpty) ...[
            const SizedBox(height: BfSpacing.lg),
            const BfSectionLabel('Related habit'),
            const SizedBox(height: BfSpacing.sm),
            InputDecorator(
              decoration: const InputDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  isExpanded: true,
                  value: _habitId,
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('None')),
                    for (final h in habits) DropdownMenuItem(value: h.id, child: Text(h.title)),
                  ],
                  onChanged: (v) => setState(() => _habitId = v),
                ),
              ),
            ),
          ],
          const SizedBox(height: BfSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This is about a slip'),
            subtitle: const Text('Marks the reflection without shame language'),
            value: _isRelapse,
            activeThumbColor: BfColors.accent,
            onChanged: (v) => setState(() => _isRelapse = v),
          ),
        ],
      ),
    );
  }

  String _moodLabel(double mood) {
    return switch (mood.round()) {
      1 => 'Very low',
      2 => 'Low',
      3 => 'Okay',
      4 => 'Good',
      _ => 'Great',
    };
  }
}
