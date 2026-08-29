import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
part 'user_entity.g.dart';

enum UserRole {
  @JsonValue('user')
  user,
  @JsonValue('premium_user')
  premiumUser,
  @JsonValue('admin')
  admin,
}

@freezed
abstract class UserEntity with _$UserEntity {
  const factory UserEntity({
    /// Firebase UID. Stable for the life of the install, even while anonymous.
    required String id,

    /// Null for anonymous users — they never give us one.
    String? email,
    String? name,
    @Default(true) bool isAnonymous,
    @Default(UserRole.user) UserRole role,
  }) = _UserEntity;

  factory UserEntity.fromJson(Map<String, dynamic> json) =>
      _$UserEntityFromJson(json);
}
