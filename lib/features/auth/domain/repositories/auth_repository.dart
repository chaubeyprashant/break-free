import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// The signed-in user right now, or null before the first sign-in completes.
  UserEntity? get currentUser;

  Stream<UserEntity?> authStateChanges();

  /// Signs in without asking for anything. The user gets a durable Firebase
  /// identity without handing over an email for a habit they'd rather not
  /// attach their name to.
  Future<UserEntity> signInAnonymously();

  Future<void> signOut();
}
