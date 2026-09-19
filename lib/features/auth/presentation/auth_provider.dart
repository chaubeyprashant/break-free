import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:break_free/features/auth/data/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._repository) {
    _repository.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _setError(null);
    try {
      await _repository.signInAnonymously();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _setError(null);
    try {
      final credential = await _repository.signInWithGoogle();
      _setLoading(false);
      return credential != null; // returns true if signed in, false if canceled
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }
}
