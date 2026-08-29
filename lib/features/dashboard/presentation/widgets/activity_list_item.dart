import 'package:flutter/material.dart';
import '../../domain/entities/activity_entity.dart';
import 'package:intl/intl.dart'; // We'll need to run flutter pub add intl if it's not already there. (It usually is)

class ActivityListItem extends StatelessWidget {
  final ActivityEntity activity;

  const ActivityListItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      switch (activity.iconType) {
        case 'check_in':
          return Icons.check_circle_rounded;
        case 'relapse':
          return Icons.warning_rounded;
        case 'achievement':
          return Icons.star_rounded;
        default:
          return Icons.notifications_rounded;
      }
    }

    Color getColor() {
      switch (activity.iconType) {
        case 'check_in':
          return Colors.green;
        case 'relapse':
          return Colors.red;
        case 'achievement':
          return Colors.orange;
        default:
          return Theme.of(context).colorScheme.primary;
      }
    }

    // Format timestamp nicely
    final timeFormat = DateFormat('MMM d, h:mm a').format(activity.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: getColor().withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(getIcon(), color: getColor(), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Text(
            timeFormat,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
