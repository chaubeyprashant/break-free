import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.watch(firebaseAuthProvider));
});

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository(this._auth);

  @override
  UserEntity? get currentUser => _toEntity(_auth.currentUser);

  @override
  Stream<UserEntity?> authStateChanges() =>
      _auth.authStateChanges().map(_toEntity);

  @override
  Future<UserEntity> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    final user = _toEntity(credential.user);
    if (user == null) {
      throw StateError('Firebase returned no user for anonymous sign-in');
    }
    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  UserEntity? _toEntity(User? user) {
    if (user == null) return null;
    return UserEntity(
      id: user.uid,
      email: user.email,
      name: user.displayName,
      isAnonymous: user.isAnonymous,
    );
  }
}
