import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountabilityRepository {
  static const MethodChannel _channel = MethodChannel('app.breakfree.mobile/app_blocker');
  
  static const String _partnerNameKey = 'accountability_partner_name';
  static const String _partnerPhoneKey = 'accountability_partner_phone';

  Future<void> savePartner(String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_partnerNameKey, name);
    await prefs.setString(_partnerPhoneKey, phone);
  }

  Future<Map<String, String?>> getPartner() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_partnerNameKey),
      'phone': prefs.getString(_partnerPhoneKey),
    };
  }

  Future<void> sendSmsOnRelapse(String habit) async {
    final partner = await getPartner();
    final phone = partner['phone'];
    
    if (phone != null && phone.isNotEmpty) {
      final message = 'Break Free Alert: I just slipped up on my goal to quit $habit. Please check in on me.';
      try {
        await _channel.invokeMethod('sendSms', {
          'phoneNumber': phone,
          'message': message,
        });
      } on PlatformException catch (e) {
        print("Failed to send SMS: '${e.message}'.");
      }
    }
  }
}

final accountabilityRepository = AccountabilityRepository();
