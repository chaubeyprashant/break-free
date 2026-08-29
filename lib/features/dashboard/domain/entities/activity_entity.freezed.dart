// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'activity_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ActivityEntity {

 String get id; String get title; String get description; DateTime get timestamp; String get iconType;
/// Create a copy of ActivityEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActivityEntityCopyWith<ActivityEntity> get copyWith => _$ActivityEntityCopyWithImpl<ActivityEntity>(this as ActivityEntity, _$identity);

  /// Serializes this ActivityEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActivityEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.iconType, iconType) || other.iconType == iconType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,timestamp,iconType);

@override
String toString() {
  return 'ActivityEntity(id: $id, title: $title, description: $description, timestamp: $timestamp, iconType: $iconType)';
}


}

/// @nodoc
abstract mixin class $ActivityEntityCopyWith<$Res>  {
  factory $ActivityEntityCopyWith(ActivityEntity value, $Res Function(ActivityEntity) _then) = _$ActivityEntityCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, DateTime timestamp, String iconType
});




}
/// @nodoc
class _$ActivityEntityCopyWithImpl<$Res>
    implements $ActivityEntityCopyWith<$Res> {
  _$ActivityEntityCopyWithImpl(this._self, this._then);

  final ActivityEntity _self;
  final $Res Function(ActivityEntity) _then;

/// Create a copy of ActivityEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? timestamp = null,Object? iconType = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,iconType: null == iconType ? _self.iconType : iconType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ActivityEntity].
extension ActivityEntityPatterns on ActivityEntity {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ActivityEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ActivityEntity() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ActivityEntity value)  $default,){
final _that = this;
switch (_that) {
case _ActivityEntity():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ActivityEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ActivityEntity() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  DateTime timestamp,  String iconType)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ActivityEntity() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.timestamp,_that.iconType);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  DateTime timestamp,  String iconType)  $default,) {final _that = this;
switch (_that) {
case _ActivityEntity():
return $default(_that.id,_that.title,_that.description,_that.timestamp,_that.iconType);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  DateTime timestamp,  String iconType)?  $default,) {final _that = this;
switch (_that) {
case _ActivityEntity() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.timestamp,_that.iconType);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ActivityEntity implements ActivityEntity {
  const _ActivityEntity({required this.id, required this.title, required this.description, required this.timestamp, required this.iconType});
  factory _ActivityEntity.fromJson(Map<String, dynamic> json) => _$ActivityEntityFromJson(json);

@override final  String id;
@override final  String title;
@override final  String description;
@override final  DateTime timestamp;
@override final  String iconType;

/// Create a copy of ActivityEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ActivityEntityCopyWith<_ActivityEntity> get copyWith => __$ActivityEntityCopyWithImpl<_ActivityEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ActivityEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ActivityEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.iconType, iconType) || other.iconType == iconType));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,description,timestamp,iconType);

@override
String toString() {
  return 'ActivityEntity(id: $id, title: $title, description: $description, timestamp: $timestamp, iconType: $iconType)';
}


}

/// @nodoc
abstract mixin class _$ActivityEntityCopyWith<$Res> implements $ActivityEntityCopyWith<$Res> {
  factory _$ActivityEntityCopyWith(_ActivityEntity value, $Res Function(_ActivityEntity) _then) = __$ActivityEntityCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, DateTime timestamp, String iconType
});




}
/// @nodoc
class __$ActivityEntityCopyWithImpl<$Res>
    implements _$ActivityEntityCopyWith<$Res> {
  __$ActivityEntityCopyWithImpl(this._self, this._then);

  final _ActivityEntity _self;
  final $Res Function(_ActivityEntity) _then;

/// Create a copy of ActivityEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? timestamp = null,Object? iconType = null,}) {
  return _then(_ActivityEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,iconType: null == iconType ? _self.iconType : iconType // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
