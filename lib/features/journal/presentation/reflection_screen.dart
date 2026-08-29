import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:break_free/core/data/relapse_log_repository.dart';
import 'package:break_free/core/insights/relapse_insights.dart';
import 'package:break_free/core/models/relapse_record.dart';

class ReflectionScreen extends StatefulWidget {
  const ReflectionScreen({super.key});

  @override
  State<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends State<ReflectionScreen> {
  late Future<List<RelapseRecord>> _records;

  @override
  void initState() {
    super.initState();
    _records = context.read<RelapseLogRepository>().getRecords();
  }

  Future<void> _reload() async {
    final reloaded = context.read<RelapseLogRepository>().getRecords();
    setState(() => _records = reloaded);
    await reloaded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reflection')),
      body: FutureBuilder<List<RelapseRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? const <RelapseRecord>[];
          final insights = RelapseInsights.from(records);

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (records.isEmpty)
                  _buildEmptyState(context)
                else ...[
                  _buildHeadline(context, insights),
                  const SizedBox(height: 20),
                  if (insights.hasPatterns)
                    ..._buildPatternCards(context, insights)
                  else
                    _buildNotEnoughYet(context, insights),
                  const SizedBox(height: 28),
                  _buildHistory(context, records),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Icon(
            Icons.auto_graph_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 20),
          Text(
            'Nothing to reflect on yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When you log a slip, this is where you will see what tends to '
            'set it off, and when.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeadline(BuildContext context, RelapseInsights insights) {
    final lastSlip = insights.lastSlip;
    final days = lastSlip == null
        ? null
        : DateTime.now().difference(lastSlip).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your patterns',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          days == null
              ? '${insights.totalSlips} logged so far.'
              : '${insights.totalSlips} logged so far. Last one '
                    '${days == 0 ? 'today' : days == 1 ? 'yesterday' : '$days days ago'}.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildNotEnoughYet(BuildContext context, RelapseInsights insights) {
    final remaining = insights.slipsUntilPatterns;
    return _InsightCard(
      icon: Icons.hourglass_empty_rounded,
      color: Theme.of(context).colorScheme.primary,
      title: 'Still learning',
      body:
          'One or two slips do not make a pattern. After '
          '$remaining more ${remaining == 1 ? 'entry' : 'entries'}, this page '
          'will start showing what they have in common.',
    );
  }

  List<Widget> _buildPatternCards(
    BuildContext context,
    RelapseInsights insights,
  ) {
    final cards = <Widget>[];

    final trigger = insights.topTrigger;
    if (trigger != null) {
      cards.add(
        _InsightCard(
          icon: Icons.bolt_rounded,
          color: Colors.orange,
          title: 'Most common trigger',
          body:
              '$trigger is behind ${insights.topTriggerCount} of your '
              '${insights.totalSlips} slips.',
        ),
      );
    }

    final window = insights.riskiestWindow;
    if (window != null) {
      cards.add(
        _InsightCard(
          icon: Icons.schedule_rounded,
          color: Colors.blue,
          title: 'Riskiest time of day',
          body:
              '${window.label} (${window.range}) — '
              '${insights.riskiestWindowCount} of ${insights.totalSlips}.',
        ),
      );
    }

    final weekday = insights.riskiestWeekday;
    if (weekday != null) {
      cards.add(
        _InsightCard(
          icon: Icons.calendar_today_rounded,
          color: Colors.purple,
          title: 'Riskiest day',
          body:
              '${_weekdayName(weekday)}s — '
              '${insights.riskiestWeekdayCount} of ${insights.totalSlips}.',
        ),
      );
    }

    return cards;
  }

  Widget _buildHistory(BuildContext context, List<RelapseRecord> records) {
    final formatter = DateFormat('MMM d, h:mm a');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent slips',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...records
            .take(10)
            .map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, right: 12),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.habitTitle == null
                                ? record.trigger
                                : '${record.habitTitle} — ${record.trigger}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            formatter.format(record.timestamp),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  /// 2024-01-01 was a Monday, so offsetting from it gives the weekday name in
  /// the user's locale rather than a hardcoded English list.
  String _weekdayName(int weekday) {
    final reference = DateTime(2024, 1, weekday);
    return DateFormat('EEEE').format(reference);
  }
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
