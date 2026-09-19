import 'package:flutter/material.dart';
import 'package:break_free/features/scanner/data/notification_scanner_repository.dart';

class ScannerSettingsScreen extends StatefulWidget {
  const ScannerSettingsScreen({super.key});

  @override
  State<ScannerSettingsScreen> createState() => _ScannerSettingsScreenState();
}

class _ScannerSettingsScreenState extends State<ScannerSettingsScreen> with WidgetsBindingObserver {
  final _repository = NotificationScannerRepository();
  bool _isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkServiceStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkServiceStatus();
    }
  }

  Future<void> _checkServiceStatus() async {
    final isEnabled = await _repository.isScannerEnabled();
    setState(() {
      _isServiceEnabled = isEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Scanner')),
      body: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _isServiceEnabled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isServiceEnabled ? Icons.check_circle : Icons.warning,
                  color: _isServiceEnabled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isServiceEnabled ? 'Scanner Active' : 'Permission Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isServiceEnabled ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        _isServiceEnabled 
                          ? 'We are scanning for suspicious transactions.'
                          : 'Please enable Notification Access so we can scan for relapses.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!_isServiceEnabled)
                  ElevatedButton(
                    onPressed: () {
                      _repository.openScannerSettings();
                    },
                    child: const Text('Enable'),
                  )
              ],
            ),
          ),
          const ListTile(
            title: Text('How it works'),
            subtitle: Text('Break Free will securely scan your incoming notifications for keywords like "smoke", "vape", or "tobacco". If a suspicious transaction is detected, we will instantly intervene.'),
          ),
        ],
      ),
    );
  }
}
