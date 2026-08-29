// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_stats_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DashboardStatsEntity {

 int get currentStreak;/// Streak length in hours, so day one can show progress instead of a zero.
 int get currentStreakHours; int get totalCheckIns; int get shieldsAvailable; int get totalCoins; List<double> get weeklyProgressXP; bool get hasCheckedInToday;
/// Create a copy of DashboardStatsEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStatsEntityCopyWith<DashboardStatsEntity> get copyWith => _$DashboardStatsEntityCopyWithImpl<DashboardStatsEntity>(this as DashboardStatsEntity, _$identity);

  /// Serializes this DashboardStatsEntity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardStatsEntity&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.currentStreakHours, currentStreakHours) || other.currentStreakHours == currentStreakHours)&&(identical(other.totalCheckIns, totalCheckIns) || other.totalCheckIns == totalCheckIns)&&(identical(other.shieldsAvailable, shieldsAvailable) || other.shieldsAvailable == shieldsAvailable)&&(identical(other.totalCoins, totalCoins) || other.totalCoins == totalCoins)&&const DeepCollectionEquality().equals(other.weeklyProgressXP, weeklyProgressXP)&&(identical(other.hasCheckedInToday, hasCheckedInToday) || other.hasCheckedInToday == hasCheckedInToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentStreak,currentStreakHours,totalCheckIns,shieldsAvailable,totalCoins,const DeepCollectionEquality().hash(weeklyProgressXP),hasCheckedInToday);

@override
String toString() {
  return 'DashboardStatsEntity(currentStreak: $currentStreak, currentStreakHours: $currentStreakHours, totalCheckIns: $totalCheckIns, shieldsAvailable: $shieldsAvailable, totalCoins: $totalCoins, weeklyProgressXP: $weeklyProgressXP, hasCheckedInToday: $hasCheckedInToday)';
}


}

/// @nodoc
abstract mixin class $DashboardStatsEntityCopyWith<$Res>  {
  factory $DashboardStatsEntityCopyWith(DashboardStatsEntity value, $Res Function(DashboardStatsEntity) _then) = _$DashboardStatsEntityCopyWithImpl;
@useResult
$Res call({
 int currentStreak, int currentStreakHours, int totalCheckIns, int shieldsAvailable, int totalCoins, List<double> weeklyProgressXP, bool hasCheckedInToday
});




}
/// @nodoc
class _$DashboardStatsEntityCopyWithImpl<$Res>
    implements $DashboardStatsEntityCopyWith<$Res> {
  _$DashboardStatsEntityCopyWithImpl(this._self, this._then);

  final DashboardStatsEntity _self;
  final $Res Function(DashboardStatsEntity) _then;

/// Create a copy of DashboardStatsEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentStreak = null,Object? currentStreakHours = null,Object? totalCheckIns = null,Object? shieldsAvailable = null,Object? totalCoins = null,Object? weeklyProgressXP = null,Object? hasCheckedInToday = null,}) {
  return _then(_self.copyWith(
currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,currentStreakHours: null == currentStreakHours ? _self.currentStreakHours : currentStreakHours // ignore: cast_nullable_to_non_nullable
as int,totalCheckIns: null == totalCheckIns ? _self.totalCheckIns : totalCheckIns // ignore: cast_nullable_to_non_nullable
as int,shieldsAvailable: null == shieldsAvailable ? _self.shieldsAvailable : shieldsAvailable // ignore: cast_nullable_to_non_nullable
as int,totalCoins: null == totalCoins ? _self.totalCoins : totalCoins // ignore: cast_nullable_to_non_nullable
as int,weeklyProgressXP: null == weeklyProgressXP ? _self.weeklyProgressXP : weeklyProgressXP // ignore: cast_nullable_to_non_nullable
as List<double>,hasCheckedInToday: null == hasCheckedInToday ? _self.hasCheckedInToday : hasCheckedInToday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardStatsEntity].
extension DashboardStatsEntityPatterns on DashboardStatsEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardStatsEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardStatsEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardStatsEntity value)  $default,){
final _that = this;
switch (_that) {
case _DashboardStatsEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardStatsEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardStatsEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int currentStreak,  int currentStreakHours,  int totalCheckIns,  int shieldsAvailable,  int totalCoins,  List<double> weeklyProgressXP,  bool hasCheckedInToday)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardStatsEntity() when $default != null:
return $default(_that.currentStreak,_that.currentStreakHours,_that.totalCheckIns,_that.shieldsAvailable,_that.totalCoins,_that.weeklyProgressXP,_that.hasCheckedInToday);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int currentStreak,  int currentStreakHours,  int totalCheckIns,  int shieldsAvailable,  int totalCoins,  List<double> weeklyProgressXP,  bool hasCheckedInToday)  $default,) {final _that = this;
switch (_that) {
case _DashboardStatsEntity():
return $default(_that.currentStreak,_that.currentStreakHours,_that.totalCheckIns,_that.shieldsAvailable,_that.totalCoins,_that.weeklyProgressXP,_that.hasCheckedInToday);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int currentStreak,  int currentStreakHours,  int totalCheckIns,  int shieldsAvailable,  int totalCoins,  List<double> weeklyProgressXP,  bool hasCheckedInToday)?  $default,) {final _that = this;
switch (_that) {
case _DashboardStatsEntity() when $default != null:
return $default(_that.currentStreak,_that.currentStreakHours,_that.totalCheckIns,_that.shieldsAvailable,_that.totalCoins,_that.weeklyProgressXP,_that.hasCheckedInToday);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardStatsEntity implements DashboardStatsEntity {
  const _DashboardStatsEntity({required this.currentStreak, required this.currentStreakHours, required this.totalCheckIns, required this.shieldsAvailable, required this.totalCoins, required final  List<double> weeklyProgressXP, required this.hasCheckedInToday}): _weeklyProgressXP = weeklyProgressXP;
  factory _DashboardStatsEntity.fromJson(Map<String, dynamic> json) => _$DashboardStatsEntityFromJson(json);

@override final  int currentStreak;
/// Streak length in hours, so day one can show progress instead of a zero.
@override final  int currentStreakHours;
@override final  int totalCheckIns;
@override final  int shieldsAvailable;
@override final  int totalCoins;
 final  List<double> _weeklyProgressXP;
@override List<double> get weeklyProgressXP {
  if (_weeklyProgressXP is EqualUnmodifiableListView) return _weeklyProgressXP;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_weeklyProgressXP);
}

@override final  bool hasCheckedInToday;

/// Create a copy of DashboardStatsEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStatsEntityCopyWith<_DashboardStatsEntity> get copyWith => __$DashboardStatsEntityCopyWithImpl<_DashboardStatsEntity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardStatsEntityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardStatsEntity&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.currentStreakHours, currentStreakHours) || other.currentStreakHours == currentStreakHours)&&(identical(other.totalCheckIns, totalCheckIns) || other.totalCheckIns == totalCheckIns)&&(identical(other.shieldsAvailable, shieldsAvailable) || other.shieldsAvailable == shieldsAvailable)&&(identical(other.totalCoins, totalCoins) || other.totalCoins == totalCoins)&&const DeepCollectionEquality().equals(other._weeklyProgressXP, _weeklyProgressXP)&&(identical(other.hasCheckedInToday, hasCheckedInToday) || other.hasCheckedInToday == hasCheckedInToday));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentStreak,currentStreakHours,totalCheckIns,shieldsAvailable,totalCoins,const DeepCollectionEquality().hash(_weeklyProgressXP),hasCheckedInToday);

@override
String toString() {
  return 'DashboardStatsEntity(currentStreak: $currentStreak, currentStreakHours: $currentStreakHours, totalCheckIns: $totalCheckIns, shieldsAvailable: $shieldsAvailable, totalCoins: $totalCoins, weeklyProgressXP: $weeklyProgressXP, hasCheckedInToday: $hasCheckedInToday)';
}


}

/// @nodoc
abstract mixin class _$DashboardStatsEntityCopyWith<$Res> implements $DashboardStatsEntityCopyWith<$Res> {
  factory _$DashboardStatsEntityCopyWith(_DashboardStatsEntity value, $Res Function(_DashboardStatsEntity) _then) = __$DashboardStatsEntityCopyWithImpl;
@override @useResult
$Res call({
 int currentStreak, int currentStreakHours, int totalCheckIns, int shieldsAvailable, int totalCoins, List<double> weeklyProgressXP, bool hasCheckedInToday
});




}
/// @nodoc
class __$DashboardStatsEntityCopyWithImpl<$Res>
    implements _$DashboardStatsEntityCopyWith<$Res> {
  __$DashboardStatsEntityCopyWithImpl(this._self, this._then);

  final _DashboardStatsEntity _self;
  final $Res Function(_DashboardStatsEntity) _then;

/// Create a copy of DashboardStatsEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentStreak = null,Object? currentStreakHours = null,Object? totalCheckIns = null,Object? shieldsAvailable = null,Object? totalCoins = null,Object? weeklyProgressXP = null,Object? hasCheckedInToday = null,}) {
  return _then(_DashboardStatsEntity(
currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,currentStreakHours: null == currentStreakHours ? _self.currentStreakHours : currentStreakHours // ignore: cast_nullable_to_non_nullable
as int,totalCheckIns: null == totalCheckIns ? _self.totalCheckIns : totalCheckIns // ignore: cast_nullable_to_non_nullable
as int,shieldsAvailable: null == shieldsAvailable ? _self.shieldsAvailable : shieldsAvailable // ignore: cast_nullable_to_non_nullable
as int,totalCoins: null == totalCoins ? _self.totalCoins : totalCoins // ignore: cast_nullable_to_non_nullable
as int,weeklyProgressXP: null == weeklyProgressXP ? _self._weeklyProgressXP : weeklyProgressXP // ignore: cast_nullable_to_non_nullable
as List<double>,hasCheckedInToday: null == hasCheckedInToday ? _self.hasCheckedInToday : hasCheckedInToday // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
