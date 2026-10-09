import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:break_free/core/theme/bf_colors.dart';
import 'package:break_free/core/theme/bf_spacing.dart';
import 'package:break_free/core/widgets/bf_components.dart';
import 'package:break_free/features/companion/data/companion_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanionDashboardScreen extends StatefulWidget {
  const CompanionDashboardScreen({super.key});

  @override
  State<CompanionDashboardScreen> createState() => _CompanionDashboardScreenState();
}

class _CompanionDashboardScreenState extends State<CompanionDashboardScreen> {
  final _linkController = TextEditingController();
  String? _companionId;
  String? _myShortCode;
  String _companionName = 'My Companion';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanion();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanion() async {
    try {
      final id = await companionRepository.getCompanionId();
      final shortCode = await companionRepository.getOrGenerateShortCode();
      var name = 'My Companion';
      if (id != null && id.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        name = prefs.getString('companion_name_$id') ?? 'My Companion';
      }
      if (mounted) {
        setState(() {
          _companionId = id;
          _myShortCode = shortCode;
          _companionName = name;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setCompanionName(String name) async {
    if (_companionId == null || _companionId!.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companion_name_$_companionId', name);
    setState(() => _companionName = name);
  }

  void _showEditNameDialog() {
    final tc = TextEditingController(text: _companionName == 'My Companion' ? '' : _companionName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Companion nickname'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: 'e.g. Alex'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _setCompanionName(tc.text.trim().isEmpty ? 'My Companion' : tc.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkPartner() async {
    final inputId = _linkController.text.trim();
    if (inputId.isEmpty) return;

    try {
      await companionRepository.linkCompanion(inputId);
      if (mounted) {
        setState(() => _companionId = inputId);
        _loadCompanion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('not found') ? 'Code not found.' : 'Failed to link.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    final myId = _myShortCode ?? '—';
    final linked = _companionId != null && _companionId!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Companion')),
      body: linked ? _buildDashboard() : _buildLinkUi(myId),
    );
  }

  Widget _buildLinkUi(String myId) {
    return ListView(
      padding: const EdgeInsets.all(BfSpacing.xxl),
      children: [
        Text(
          'Accountability companion',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: BfSpacing.sm),
        Text(
          'Share a short code with someone you trust. They see high-level alerts — not browsing history.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: BfSpacing.xxl),
        const BfSectionLabel('Your invite code'),
        const SizedBox(height: BfSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                myId,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: myId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied')),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: BfSpacing.xxl),
        const BfSectionLabel('Enter their code'),
        const SizedBox(height: BfSpacing.sm),
        TextField(
          controller: _linkController,
          decoration: const InputDecoration(hintText: 'Companion invite code'),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: BfSpacing.md),
        BfPrimaryButton(label: 'Connect', onPressed: _linkPartner),
      ],
    );
  }

  Widget _buildDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, BfSpacing.sm, BfSpacing.screenH, BfSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BfSectionLabel('Linked with'),
              const SizedBox(height: BfSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _companionName,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: _showEditNameDialog,
                    tooltip: 'Rename',
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  await companionRepository.linkCompanion('');
                  setState(() => _companionId = null);
                },
                child: Text(
                  'Unlink',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: BfSpacing.screenH),
          child: BfSectionLabel('Recent activity'),
        ),
        const SizedBox(height: BfSpacing.xs),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: companionRepository.streamCompanionRelapses(_companionId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return BfEmptyState(
                  title: 'No alerts yet',
                  body: '$_companionName has no synced events.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(BfSpacing.screenH, 0, BfSpacing.screenH, BfSpacing.huge),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (_, __) => const BfDivider(),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final lat = data['lat'] as double?;
                  final lng = data['lng'] as double?;
                  final locationAddress = data['locationAddress'] as String?;
                  final formattedTime = timestamp != null
                      ? DateFormat.jm().add_yMMMd().format(timestamp)
                      : 'Just now';

                  var title = data['habitTitle'] as String? ?? 'Event';
                  var kind = data['kind'] as String? ?? 'slip';

                  if (title.startsWith('Tried to open: ')) {
                    kind = 'App blocked';
                    title = title.replaceFirst('Tried to open: ', '');
                  } else if (title.startsWith('Tried to open restricted app: ')) {
                    kind = 'App blocked';
                    title = title.replaceFirst('Tried to open restricted app: ', '');
                  } else if (kind == 'protection_alert') {
                    kind = 'Protection';
                  } else {
                    kind = 'Slip';
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: BfSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kind.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.1,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                        ),
                        const SizedBox(height: BfSpacing.xxs),
                        Text(title, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: BfSpacing.xxs),
                        Text(formattedTime, style: Theme.of(context).textTheme.bodySmall),
                        if (locationAddress != null || (lat != null && lng != null)) ...[
                          const SizedBox(height: BfSpacing.xs),
                          InkWell(
                            onTap: () async {
                              if (lat != null && lng != null) {
                                final uri = Uri.parse(
                                  'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
                                );
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri);
                                }
                              }
                            },
                            child: Text(
                              locationAddress ?? '$lat, $lng',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: BfColors.accent,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
