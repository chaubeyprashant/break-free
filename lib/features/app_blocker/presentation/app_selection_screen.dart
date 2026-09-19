import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:break_free/features/app_blocker/data/app_blocker_repository.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> {
  bool _isAccessibilityEnabled = false;
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
    _fetchApps();
  }

  Future<void> _checkPermission() async {
    final enabled = await appBlockerRepository.isAccessibilityServiceEnabled();
    setState(() {
      _isAccessibilityEnabled = enabled;
    });
  }

  Future<void> _fetchApps() async {
    try {
      // exclude system apps, with icon
      final apps = await InstalledApps.getInstalledApps();
      // Sort alphabetically
      apps.sort((a, b) => (a.name ?? '').toLowerCase().compareTo((b.name ?? '').toLowerCase()));
      
      setState(() {
        _installedApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching apps: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterApps(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredApps = _installedApps;
      } else {
        _filteredApps = _installedApps.where((app) {
          final name = (app.name ?? '').toLowerCase();
          final pkg = (app.packageName ?? '').toLowerCase();
          return name.contains(query.toLowerCase()) || pkg.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkPermission();
              setState(() { _isLoading = true; });
              _fetchApps();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: _isAccessibilityEnabled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isAccessibilityEnabled ? Icons.check_circle : Icons.warning,
                  color: _isAccessibilityEnabled ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAccessibilityEnabled 
                            ? 'Tracking Active' 
                            : 'Permission Required',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isAccessibilityEnabled
                            ? 'Break Free is monitoring your apps.'
                            : 'Enable Accessibility service to block apps.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!_isAccessibilityEnabled)
                  ElevatedButton(
                    onPressed: () async {
                      await appBlockerRepository.openAccessibilitySettings();
                    },
                    child: const Text('Enable'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search for games or apps...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: _filterApps,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = _filteredApps[index];
                      final isBlocked = appBlockerRepository.blockedApps.contains(app.packageName);
                      
                      return SwitchListTile(
                        secondary: app.icon != null 
                            ? Image.memory(app.icon!, width: 40, height: 40)
                            : const Icon(Icons.android, size: 40),
                        title: Text(app.name ?? 'Unknown App'),
                        subtitle: Text(app.packageName ?? ''),
                        value: isBlocked,
                        onChanged: (value) async {
                          if (!_isAccessibilityEnabled && value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enable Accessibility permission first.')),
                            );
                            return;
                          }
                          await appBlockerRepository.toggleAppBlock(app.packageName!, value);
                          setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
