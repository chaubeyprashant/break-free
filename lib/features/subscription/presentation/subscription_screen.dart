import 'package:flutter/material.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Unlock Full Potential',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildFeatureRow(context, 'Streak Tracking', true, true),
            _buildFeatureRow(context, 'Basic Panic Button', true, true),
            _buildFeatureRow(context, 'Advanced Statistics', false, true),
            _buildFeatureRow(context, 'Guided Meditations', false, true),
            _buildFeatureRow(context, 'Dark Mode', false, true),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Mock payment
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Subscribed to Premium!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: const Text('Subscribe Now - \$4.99/mo'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context,
    String feature,
    bool free,
    bool premium,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(feature)),
          if (free)
            const Icon(Icons.check, color: Colors.green)
          else
            const Icon(Icons.close, color: Colors.grey),
          const SizedBox(width: 32),
          if (premium)
            const Icon(Icons.check, color: Colors.green)
          else
            const Icon(Icons.close, color: Colors.grey),
        ],
      ),
    );
  }
}
