import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/app_blocker/data/app_blocker_repository.dart';

class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen> with WidgetsBindingObserver {
  bool _isAccessibilityEnabled = false;
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filteredApps = [];
  List<String> _supportedBrowsers = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _loadSupportedBrowsers();
    _fetchApps();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final enabled = await appBlockerRepository.isAccessibilityServiceEnabled();
    if (!mounted) return;
    setState(() => _isAccessibilityEnabled = enabled);
  }

  Future<void> _loadSupportedBrowsers() async {
    final browsers = await appBlockerRepository.getSupportedBrowsers();
    if (!mounted) return;
    setState(() => _supportedBrowsers = browsers);
  }

  Future<void> _fetchApps() async {
    try {
      final apps = await InstalledApps.getInstalledApps();
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _installedApps = apps;
        _filteredApps = apps;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching apps: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _filterApps(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredApps = _installedApps;
      } else {
        final q = query.toLowerCase();
        _filteredApps = _installedApps.where((app) {
          return app.name.toLowerCase().contains(q) || app.packageName.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  String get _browserListText {
    if (_supportedBrowsers.isEmpty) return 'supported browsers';
    if (_supportedBrowsers.length == 1) return _supportedBrowsers.first;
    final head = _supportedBrowsers.sublist(0, _supportedBrowsers.length - 1).join(', ');
    return '$head and ${_supportedBrowsers.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Protected apps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _checkPermission();
              setState(() => _isLoading = true);
              _fetchApps();
            },
          ),
        ],
      ),
      body: _isAccessibilityEnabled ? _buildBlockerList(context) : _buildDisclosure(context),
    );
  }

  Widget _buildBlockerList(BuildContext context) {
    final blockedCount = appBlockerRepository.blockedApps.length;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$blockedCount apps protected',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: BfSpacing.xxs),
              Text(
                'Website filtering works in $_browserListText only. Other browsers are not covered.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.xs),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search apps',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: _filterApps,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  itemCount: _filteredApps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: BfSpacing.screenH),
                  itemBuilder: (context, index) {
                    final app = _filteredApps[index];
                    final isBlocked = appBlockerRepository.blockedApps.contains(app.packageName);
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: BfSpacing.screenH),
                      secondary: app.icon != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(app.icon!, width: 36, height: 36),
                            )
                          : const Icon(Icons.apps, size: 36),
                      title: Text(app.name, style: Theme.of(context).textTheme.titleSmall),
                      subtitle: Text(
                        app.packageName,
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: isBlocked,
                      activeThumbColor: BfColors.accent,
                      onChanged: (value) async {
                        await appBlockerRepository.toggleAppBlock(app.packageName, value);
                        if (!mounted) return;
                        setState(() {});
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDisclosure(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(BfSpacing.xxl),
      children: [
        Text(
          'Accessibility access',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: BfSpacing.md),
        Text(
          'Break Free uses Accessibility to:\n\n'
          '• Notice when you open an app you chose to block\n'
          '• Read the address bar of $_browserListText for website filters\n\n'
          'Detection stays on your device. Addresses are not stored. '
          'If you link a companion, they may get a short alert — not browsing history.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        const SizedBox(height: BfSpacing.xxl),
        BfPrimaryButton(
          label: 'Open Accessibility settings',
          onPressed: () => appBlockerRepository.openAccessibilitySettings(),
        ),
        const SizedBox(height: BfSpacing.xs),
        BfSecondaryButton(
          label: 'Not now',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
