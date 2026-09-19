import 'package:flutter/material.dart';
import 'package:break_free/features/settings/data/accountability_repository.dart';

class AccountabilitySettingsScreen extends StatefulWidget {
  const AccountabilitySettingsScreen({super.key});

  @override
  State<AccountabilitySettingsScreen> createState() => _AccountabilitySettingsScreenState();
}

class _AccountabilitySettingsScreenState extends State<AccountabilitySettingsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartner();
  }

  Future<void> _loadPartner() async {
    final partner = await accountabilityRepository.getPartner();
    setState(() {
      _nameController.text = partner['name'] ?? '';
      _phoneController.text = partner['phone'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _savePartner() async {
    await accountabilityRepository.savePartner(
      _nameController.text.trim(),
      _phoneController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accountability Partner saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accountability Partner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add someone you trust.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We will automatically send them an SMS text message if you slip up and trigger an intervention.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Partner Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number (include country code)',
                border: OutlineInputBorder(),
                hintText: '+1234567890',
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savePartner,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Partner'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
