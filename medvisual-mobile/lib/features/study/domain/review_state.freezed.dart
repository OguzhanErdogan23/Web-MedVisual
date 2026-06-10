// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'review_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReviewState {

 double get easeFactor; double get intervalDays; int get repetitions; DateTime? get dueAt; int? get lastGrade;
/// Create a copy of ReviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReviewStateCopyWith<ReviewState> get copyWith => _$ReviewStateCopyWithImpl<ReviewState>(this as ReviewState, _$identity);

  /// Serializes this ReviewState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReviewState&&(identical(other.easeFactor, easeFactor) || other.easeFactor == easeFactor)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.lastGrade, lastGrade) || other.lastGrade == lastGrade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,easeFactor,intervalDays,repetitions,dueAt,lastGrade);

@override
String toString() {
  return 'ReviewState(easeFactor: $easeFactor, intervalDays: $intervalDays, repetitions: $repetitions, dueAt: $dueAt, lastGrade: $lastGrade)';
}


}

/// @nodoc
abstract mixin class $ReviewStateCopyWith<$Res>  {
  factory $ReviewStateCopyWith(ReviewState value, $Res Function(ReviewState) _then) = _$ReviewStateCopyWithImpl;
@useResult
$Res call({
 double easeFactor, double intervalDays, int repetitions, DateTime? dueAt, int? lastGrade
});




}
/// @nodoc
class _$ReviewStateCopyWithImpl<$Res>
    implements $ReviewStateCopyWith<$Res> {
  _$ReviewStateCopyWithImpl(this._self, this._then);

  final ReviewState _self;
  final $Res Function(ReviewState) _then;

/// Create a copy of ReviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? easeFactor = null,Object? intervalDays = null,Object? repetitions = null,Object? dueAt = freezed,Object? lastGrade = freezed,}) {
  return _then(_self.copyWith(
easeFactor: null == easeFactor ? _self.easeFactor : easeFactor // ignore: cast_nullable_to_non_nullable
as double,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as double,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastGrade: freezed == lastGrade ? _self.lastGrade : lastGrade // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReviewState].
extension ReviewStatePatterns on ReviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReviewState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReviewState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReviewState value)  $default,){
final _that = this;
switch (_that) {
case _ReviewState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReviewState value)?  $default,){
final _that = this;
switch (_that) {
case _ReviewState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double easeFactor,  double intervalDays,  int repetitions,  DateTime? dueAt,  int? lastGrade)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReviewState() when $default != null:
return $default(_that.easeFactor,_that.intervalDays,_that.repetitions,_that.dueAt,_that.lastGrade);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double easeFactor,  double intervalDays,  int repetitions,  DateTime? dueAt,  int? lastGrade)  $default,) {final _that = this;
switch (_that) {
case _ReviewState():
return $default(_that.easeFactor,_that.intervalDays,_that.repetitions,_that.dueAt,_that.lastGrade);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double easeFactor,  double intervalDays,  int repetitions,  DateTime? dueAt,  int? lastGrade)?  $default,) {final _that = this;
switch (_that) {
case _ReviewState() when $default != null:
return $default(_that.easeFactor,_that.intervalDays,_that.repetitions,_that.dueAt,_that.lastGrade);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReviewState implements ReviewState {
  const _ReviewState({this.easeFactor = 2.5, this.intervalDays = 0.0, this.repetitions = 0, this.dueAt, this.lastGrade});
  factory _ReviewState.fromJson(Map<String, dynamic> json) => _$ReviewStateFromJson(json);

@override@JsonKey() final  double easeFactor;
@override@JsonKey() final  double intervalDays;
@override@JsonKey() final  int repetitions;
@override final  DateTime? dueAt;
@override final  int? lastGrade;

/// Create a copy of ReviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReviewStateCopyWith<_ReviewState> get copyWith => __$ReviewStateCopyWithImpl<_ReviewState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReviewStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReviewState&&(identical(other.easeFactor, easeFactor) || other.easeFactor == easeFactor)&&(identical(other.intervalDays, intervalDays) || other.intervalDays == intervalDays)&&(identical(other.repetitions, repetitions) || other.repetitions == repetitions)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.lastGrade, lastGrade) || other.lastGrade == lastGrade));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,easeFactor,intervalDays,repetitions,dueAt,lastGrade);

@override
String toString() {
  return 'ReviewState(easeFactor: $easeFactor, intervalDays: $intervalDays, repetitions: $repetitions, dueAt: $dueAt, lastGrade: $lastGrade)';
}


}

/// @nodoc
abstract mixin class _$ReviewStateCopyWith<$Res> implements $ReviewStateCopyWith<$Res> {
  factory _$ReviewStateCopyWith(_ReviewState value, $Res Function(_ReviewState) _then) = __$ReviewStateCopyWithImpl;
@override @useResult
$Res call({
 double easeFactor, double intervalDays, int repetitions, DateTime? dueAt, int? lastGrade
});




}
/// @nodoc
class __$ReviewStateCopyWithImpl<$Res>
    implements _$ReviewStateCopyWith<$Res> {
  __$ReviewStateCopyWithImpl(this._self, this._then);

  final _ReviewState _self;
  final $Res Function(_ReviewState) _then;

/// Create a copy of ReviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? easeFactor = null,Object? intervalDays = null,Object? repetitions = null,Object? dueAt = freezed,Object? lastGrade = freezed,}) {
  return _then(_ReviewState(
easeFactor: null == easeFactor ? _self.easeFactor : easeFactor // ignore: cast_nullable_to_non_nullable
as double,intervalDays: null == intervalDays ? _self.intervalDays : intervalDays // ignore: cast_nullable_to_non_nullable
as double,repetitions: null == repetitions ? _self.repetitions : repetitions // ignore: cast_nullable_to_non_nullable
as int,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastGrade: freezed == lastGrade ? _self.lastGrade : lastGrade // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
