import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CompanionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Update FCM token for push notifications
  Future<void> updateFcmToken() async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _db.collection('users').doc(uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('FCM Token error: $e');
    }
  }

  // Get my companion's ID
  Future<String?> getCompanionId() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['companionId'] as String?;
    } catch (e) {
      print('Firestore Error: $e');
      return null;
    }
  }

  // Get or generate a short 6-character invite code
  Future<String> getOrGenerateShortCode() async {
    final uid = currentUserId;
    if (uid == null) return 'ERROR';

    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data != null && data.containsKey('shortCode')) {
      return data['shortCode'] as String;
    }

    // Generate a simple 6-character code from the UID
    final code = uid.substring(0, 6).toUpperCase();
    await _db.collection('users').doc(uid).set({
      'shortCode': code,
    }, SetOptions(merge: true));
    return code;
  }

  // Link to a companion using their short code
  Future<void> linkCompanion(String shortCode) async {
    final uid = currentUserId;
    if (uid == null) return;
    
    if (shortCode.isEmpty) {
      // Unlink (One-way unlink for now)
      await _db.collection('users').doc(uid).set({'companionId': ''}, SetOptions(merge: true));
      return;
    }

    // Find the user with this short code
    final query = await _db.collection('users').where('shortCode', isEqualTo: shortCode.toUpperCase()).limit(1).get();
    if (query.docs.isEmpty) {
      throw Exception('Companion not found with that code!');
    }

    final companionUid = query.docs.first.id;

    // Bi-directional link
    await _db.collection('users').doc(uid).set({
      'companionId': companionUid,
    }, SetOptions(merge: true));
    
    await _db.collection('users').doc(companionUid).set({
      'companionId': uid,
    }, SetOptions(merge: true));
  }

  // Stream companion's relapses
  Stream<QuerySnapshot> streamCompanionRelapses(String companionId) {
    return _db
        .collection('users')
        .doc(companionId)
        .collection('relapses')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Sync a relapse to Firestore with Location!
  Future<void> syncRelapse(String habitTitle) async {
    final uid = currentUserId;
    if (uid == null) return;

    Position? position;
    String? locationAddress;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);
              
          // Reverse geocode
          try {
            final geocoding = Geocoding();
            List<Placemark> placemarks = await geocoding.placemarkFromCoordinates(
              position.latitude, 
              position.longitude,
            );
            print('Geocoding returned ${placemarks.length} results');
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              print('Placemark: street=${p.street}, locality=${p.locality}, area=${p.administrativeArea}, subLocality=${p.subLocality}');
              final parts = [p.street, p.subLocality, p.locality, p.administrativeArea]
                  .where((e) => e != null && e.isNotEmpty)
                  .toList();
              if (parts.isNotEmpty) {
                locationAddress = parts.join(', ');
              }
            }
          } catch (e, stack) {
            print('Geocoding error: $e');
            print('Geocoding stack: $stack');
          }
        }
      }
    } catch (e) {
      print('Location error: $e');
    }

    print('Saving relapse: title=$habitTitle, address=$locationAddress, lat=${position?.latitude}, lng=${position?.longitude}');
    
    await _db.collection('users').doc(uid).collection('relapses').add({
      'habitTitle': habitTitle,
      'timestamp': FieldValue.serverTimestamp(),
      'lat': position?.latitude,
      'lng': position?.longitude,
      'locationAddress': locationAddress,
    });
  }
}

final companionRepository = CompanionRepository();
