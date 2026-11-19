import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      print('=== GOOGLE SIGN IN START ===');
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        print('=== GOOGLE SIGN IN CANCELED BY USER ===');
        return null; // The user canceled the sign-in
      }

      print('=== GOOGLE SIGN IN ACCOUNT FETCHED: ${googleUser.email} ===');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print('=== GOOGLE AUTH DETAILS FETCHED ===');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('=== FIREBASE SIGN IN IN PROGRESS ===');
      // Once signed in, return the UserCredential
      final result = await _auth.signInWithCredential(credential);
      print('=== FIREBASE SIGN IN SUCCESS: ${result.user?.uid} ===');
      return result;
    } catch (e, stackTrace) {
      print('=== GOOGLE SIGN IN EXCEPTION ===');
      print('Error: $e');
      print('Stacktrace: $stackTrace');
      print('=================================');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
