// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_home_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StudyHomeState {

 ViewStatus get status; List<CardSet> get sets; int get totalDue; int get newCount; StudyHistory? get history; String? get error;
/// Create a copy of StudyHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyHomeStateCopyWith<StudyHomeState> get copyWith => _$StudyHomeStateCopyWithImpl<StudyHomeState>(this as StudyHomeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyHomeState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.sets, sets)&&(identical(other.totalDue, totalDue) || other.totalDue == totalDue)&&(identical(other.newCount, newCount) || other.newCount == newCount)&&(identical(other.history, history) || other.history == history)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(sets),totalDue,newCount,history,error);

@override
String toString() {
  return 'StudyHomeState(status: $status, sets: $sets, totalDue: $totalDue, newCount: $newCount, history: $history, error: $error)';
}


}

/// @nodoc
abstract mixin class $StudyHomeStateCopyWith<$Res>  {
  factory $StudyHomeStateCopyWith(StudyHomeState value, $Res Function(StudyHomeState) _then) = _$StudyHomeStateCopyWithImpl;
@useResult
$Res call({
 ViewStatus status, List<CardSet> sets, int totalDue, int newCount, StudyHistory? history, String? error
});


$StudyHistoryCopyWith<$Res>? get history;

}
/// @nodoc
class _$StudyHomeStateCopyWithImpl<$Res>
    implements $StudyHomeStateCopyWith<$Res> {
  _$StudyHomeStateCopyWithImpl(this._self, this._then);

  final StudyHomeState _self;
  final $Res Function(StudyHomeState) _then;

/// Create a copy of StudyHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? sets = null,Object? totalDue = null,Object? newCount = null,Object? history = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<CardSet>,totalDue: null == totalDue ? _self.totalDue : totalDue // ignore: cast_nullable_to_non_nullable
as int,newCount: null == newCount ? _self.newCount : newCount // ignore: cast_nullable_to_non_nullable
as int,history: freezed == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as StudyHistory?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of StudyHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudyHistoryCopyWith<$Res>? get history {
    if (_self.history == null) {
    return null;
  }

  return $StudyHistoryCopyWith<$Res>(_self.history!, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}


/// Adds pattern-matching-related methods to [StudyHomeState].
extension StudyHomeStatePatterns on StudyHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyHomeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyHomeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyHomeState value)  $default,){
final _that = this;
switch (_that) {
case _StudyHomeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyHomeState value)?  $default,){
final _that = this;
switch (_that) {
case _StudyHomeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewStatus status,  List<CardSet> sets,  int totalDue,  int newCount,  StudyHistory? history,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyHomeState() when $default != null:
return $default(_that.status,_that.sets,_that.totalDue,_that.newCount,_that.history,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewStatus status,  List<CardSet> sets,  int totalDue,  int newCount,  StudyHistory? history,  String? error)  $default,) {final _that = this;
switch (_that) {
case _StudyHomeState():
return $default(_that.status,_that.sets,_that.totalDue,_that.newCount,_that.history,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewStatus status,  List<CardSet> sets,  int totalDue,  int newCount,  StudyHistory? history,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _StudyHomeState() when $default != null:
return $default(_that.status,_that.sets,_that.totalDue,_that.newCount,_that.history,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _StudyHomeState implements StudyHomeState {
  const _StudyHomeState({this.status = ViewStatus.initial, final  List<CardSet> sets = const <CardSet>[], this.totalDue = 0, this.newCount = 0, this.history, this.error}): _sets = sets;
  

@override@JsonKey() final  ViewStatus status;
 final  List<CardSet> _sets;
@override@JsonKey() List<CardSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

@override@JsonKey() final  int totalDue;
@override@JsonKey() final  int newCount;
@override final  StudyHistory? history;
@override final  String? error;

/// Create a copy of StudyHomeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyHomeStateCopyWith<_StudyHomeState> get copyWith => __$StudyHomeStateCopyWithImpl<_StudyHomeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyHomeState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._sets, _sets)&&(identical(other.totalDue, totalDue) || other.totalDue == totalDue)&&(identical(other.newCount, newCount) || other.newCount == newCount)&&(identical(other.history, history) || other.history == history)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_sets),totalDue,newCount,history,error);

@override
String toString() {
  return 'StudyHomeState(status: $status, sets: $sets, totalDue: $totalDue, newCount: $newCount, history: $history, error: $error)';
}


}

/// @nodoc
abstract mixin class _$StudyHomeStateCopyWith<$Res> implements $StudyHomeStateCopyWith<$Res> {
  factory _$StudyHomeStateCopyWith(_StudyHomeState value, $Res Function(_StudyHomeState) _then) = __$StudyHomeStateCopyWithImpl;
@override @useResult
$Res call({
 ViewStatus status, List<CardSet> sets, int totalDue, int newCount, StudyHistory? history, String? error
});


@override $StudyHistoryCopyWith<$Res>? get history;

}
/// @nodoc
class __$StudyHomeStateCopyWithImpl<$Res>
    implements _$StudyHomeStateCopyWith<$Res> {
  __$StudyHomeStateCopyWithImpl(this._self, this._then);

  final _StudyHomeState _self;
  final $Res Function(_StudyHomeState) _then;

/// Create a copy of StudyHomeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? sets = null,Object? totalDue = null,Object? newCount = null,Object? history = freezed,Object? error = freezed,}) {
  return _then(_StudyHomeState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<CardSet>,totalDue: null == totalDue ? _self.totalDue : totalDue // ignore: cast_nullable_to_non_nullable
as int,newCount: null == newCount ? _self.newCount : newCount // ignore: cast_nullable_to_non_nullable
as int,history: freezed == history ? _self.history : history // ignore: cast_nullable_to_non_nullable
as StudyHistory?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of StudyHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StudyHistoryCopyWith<$Res>? get history {
    if (_self.history == null) {
    return null;
  }

  return $StudyHistoryCopyWith<$Res>(_self.history!, (value) {
    return _then(_self.copyWith(history: value));
  });
}
}

// dart format on
