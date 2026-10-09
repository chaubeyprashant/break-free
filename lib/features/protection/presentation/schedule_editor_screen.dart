import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/models/protection_schedule.dart';
import 'package:break_free/core/providers/protection_provider.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';

class ScheduleEditorScreen extends StatefulWidget {
  const ScheduleEditorScreen({super.key, this.existing});

  final ProtectionSchedule? existing;

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  late final TextEditingController _name;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late Set<int> _days;
  late Set<String> _categories;
  late bool _enabled;

  static const _dayLabels = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? 'Night Protection');
    _start = _fromMinutes(e?.startMinutes ?? 22 * 60);
    _end = _fromMinutes(e?.endMinutes ?? 7 * 60);
    _days = {...(e?.daysOfWeek ?? {1, 2, 3, 4, 5, 6, 7})};
    _categories = {...(e?.webCategories ?? {'adult', 'custom'})};
    _enabled = e?.enabled ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  TimeOfDay _fromMinutes(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickStart() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null) setState(() => _start = t);
  }

  Future<void> _pickEnd() async {
    final t = await showTimePicker(context: context, initialTime: _end);
    if (t != null) setState(() => _end = t);
  }

  Future<void> _save() async {
    final schedule = ProtectionSchedule(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim().isEmpty ? 'Schedule' : _name.text.trim(),
      startMinutes: _toMinutes(_start),
      endMinutes: _toMinutes(_end),
      daysOfWeek: _days,
      appPackages: widget.existing?.appPackages ?? {},
      webCategories: _categories,
      enabled: _enabled,
    );
    await context.read<ProtectionProvider>().upsertSchedule(schedule);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: const Text('This removes the schedule from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<ProtectionProvider>().deleteSchedule(id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final crosses = _toMinutes(_end) <= _toMinutes(_start);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New schedule' : 'Edit schedule'),
        actions: [
          if (widget.existing != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BfSpacing.screenH,
          BfSpacing.sm,
          BfSpacing.screenH,
          BfSpacing.huge,
        ),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'Night Protection',
            ),
          ),
          const SizedBox(height: BfSpacing.md),
          BfListRow(
            title: 'Start',
            subtitle: _start.format(context),
            trailing: const Icon(Icons.schedule, size: 20),
            onTap: _pickStart,
          ),
          BfListRow(
            title: 'End',
            subtitle: _end.format(context),
            trailing: const Icon(Icons.schedule, size: 20),
            onTap: _pickEnd,
            showDivider: false,
          ),
          if (crosses) ...[
            const SizedBox(height: BfSpacing.xs),
            Text(
              'Crosses midnight — stays active overnight into the next morning.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('Days'),
          const SizedBox(height: BfSpacing.sm),
          Wrap(
            spacing: BfSpacing.xs,
            runSpacing: BfSpacing.xs,
            children: _dayLabels.entries.map((e) {
              final selected = _days.contains(e.key);
              return FilterChip(
                label: Text(e.value),
                selected: selected,
                selectedColor: BfColors.accentSoft,
                checkmarkColor: BfColors.accent,
                onSelected: (v) => setState(() {
                  if (v) {
                    _days.add(e.key);
                  } else {
                    _days.remove(e.key);
                  }
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: BfSpacing.lg),
          const BfSectionLabel('Web categories'),
          const SizedBox(height: BfSpacing.xs),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Adult'),
            value: _categories.contains('adult'),
            activeColor: BfColors.accent,
            onChanged: (v) => setState(() {
              if (v == true) {
                _categories.add('adult');
              } else {
                _categories.remove('adult');
              }
            }),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Gambling'),
            value: _categories.contains('gambling'),
            activeColor: BfColors.accent,
            onChanged: (v) => setState(() {
              if (v == true) {
                _categories.add('gambling');
              } else {
                _categories.remove('gambling');
              }
            }),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Custom domains'),
            value: _categories.contains('custom'),
            activeColor: BfColors.accent,
            onChanged: (v) => setState(() {
              if (v == true) {
                _categories.add('custom');
              } else {
                _categories.remove('custom');
              }
            }),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enabled'),
            value: _enabled,
            activeThumbColor: BfColors.accent,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          const SizedBox(height: BfSpacing.sm),
          Text(
            'Protected apps use your global blocked-apps list while this schedule is active. '
            'Edit apps from Protection Center → Protected apps.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: BfSpacing.xl),
          BfPrimaryButton(
            label: 'Save schedule',
            onPressed: _days.isEmpty ? null : _save,
          ),
        ],
      ),
    );
  }
}
