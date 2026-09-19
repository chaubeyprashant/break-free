import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _companionName = "My Companion";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanion();
  }

  Future<void> _loadCompanion() async {
    try {
      final id = await companionRepository.getCompanionId();
      final shortCode = await companionRepository.getOrGenerateShortCode();
      String name = "My Companion";
      if (id != null) {
        final prefs = await SharedPreferences.getInstance();
        name = prefs.getString('companion_name_$id') ?? "My Companion";
      }
      if (mounted) {
        setState(() {
          _companionId = id;
          _myShortCode = shortCode;
          _companionName = name;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _setCompanionName(String name) async {
    if (_companionId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companion_name_$_companionId', name);
    setState(() {
      _companionName = name;
    });
  }

  void _showEditNameDialog() {
    final tc = TextEditingController(text: _companionName == "My Companion" ? "" : _companionName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nickname Companion'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: 'e.g. John'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _setCompanionName(tc.text.trim().isEmpty ? "My Companion" : tc.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      )
    );
  }

  Future<void> _linkPartner() async {
    final inputId = _linkController.text.trim();
    if (inputId.isEmpty) return;

    try {
      await companionRepository.linkCompanion(inputId);
      if (mounted) {
        setState(() {
          _companionId = inputId; 
        });
        _loadCompanion(); // Reload to fetch nickname if any
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('not found') ? 'Code not found!' : 'Failed to link.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myId = _myShortCode ?? 'Not logged in';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion Sync'),
        elevation: 0,
        backgroundColor: _companionId == null || _companionId!.isEmpty ? null : Colors.blue.shade800,
        foregroundColor: _companionId == null || _companionId!.isEmpty ? null : Colors.white,
      ),
      backgroundColor: Colors.grey.shade50,
      body: _companionId == null || _companionId!.isEmpty
          ? _buildLinkUi(myId)
          : _buildDashboard(),
    );
  }

  Widget _buildLinkUi(String myId) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.people_alt, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 24),
          const Text(
            'Link with a Companion',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Hold each other accountable. Share your invite code with your partner, parent, or friend, or enter theirs below.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Your Invite Code:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  myId,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 2,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: myId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _linkController,
            decoration: InputDecoration(
              labelText: "Companion's Invite Code",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _linkPartner,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Connect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        // Premium Gamified Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ]
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('PROTECTING', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          Text(
                            _companionName, 
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: _showEditNameDialog,
                    tooltip: 'Rename Companion',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  await companionRepository.linkCompanion('');
                  setState(() => _companionId = null);
                },
                icon: const Icon(Icons.link_off, color: Colors.white, size: 18),
                label: const Text('Unlink Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ]
          ),
        ),
        
        // Feed Header
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Recent Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.black87),
            ),
          ),
        ),
        
        // Feed List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: companionRepository.streamCompanionRelapses(_companionId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 80, color: Colors.amber.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        "All clear! 🎉",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$_companionName hasn't slipped up.",
                        style: const TextStyle(color: Colors.black45),
                      ),
                      const SizedBox(height: 40),
                    ],
                  )
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  final lat = data['lat'] as double?;
                  final lng = data['lng'] as double?;
                  final locationAddress = data['locationAddress'] as String?;
                  final formattedTime = timestamp != null ? DateFormat.jm().add_yMMMd().format(timestamp) : 'Just now';

                  String title = data['habitTitle'] ?? 'Unknown Habit';
                  String subtitle = 'Slip-up';
                  
                  if (title.startsWith('Tried to open: ')) {
                    subtitle = 'App Blocked';
                    title = title.replaceFirst('Tried to open: ', '');
                  } else if (title.startsWith('Tried to open restricted app: ')) {
                    subtitle = 'App Blocked';
                    title = title.replaceFirst('Tried to open restricted app: ', '');
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subtitle.toUpperCase(),
                                  style: TextStyle(
                                    color: Colors.deepOrange.shade400,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  title,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black87),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade500),
                                    const SizedBox(width: 6),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                if (locationAddress != null || (lat != null && lng != null)) ...[
                                  const SizedBox(height: 12),
                                  InkWell(
                                    onTap: () async {
                                      if (lat != null && lng != null) {
                                        final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.location_on_rounded, size: 16, color: Colors.blue.shade600),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              locationAddress ?? '$lat, $lng', 
                                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                ]
                              ],
                            ),
                          ),
                        ]
                      ),
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
