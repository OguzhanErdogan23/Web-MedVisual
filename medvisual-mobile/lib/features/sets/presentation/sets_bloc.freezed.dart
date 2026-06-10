// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sets_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SetsState {

 ViewStatus get status; List<CardSet> get sets; String? get error; String? get notice;
/// Create a copy of SetsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetsStateCopyWith<SetsState> get copyWith => _$SetsStateCopyWithImpl<SetsState>(this as SetsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.sets, sets)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(sets),error,notice);

@override
String toString() {
  return 'SetsState(status: $status, sets: $sets, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class $SetsStateCopyWith<$Res>  {
  factory $SetsStateCopyWith(SetsState value, $Res Function(SetsState) _then) = _$SetsStateCopyWithImpl;
@useResult
$Res call({
 ViewStatus status, List<CardSet> sets, String? error, String? notice
});




}
/// @nodoc
class _$SetsStateCopyWithImpl<$Res>
    implements $SetsStateCopyWith<$Res> {
  _$SetsStateCopyWithImpl(this._self, this._then);

  final SetsState _self;
  final $Res Function(SetsState) _then;

/// Create a copy of SetsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? sets = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as List<CardSet>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SetsState].
extension SetsStatePatterns on SetsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetsState value)  $default,){
final _that = this;
switch (_that) {
case _SetsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetsState value)?  $default,){
final _that = this;
switch (_that) {
case _SetsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewStatus status,  List<CardSet> sets,  String? error,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetsState() when $default != null:
return $default(_that.status,_that.sets,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewStatus status,  List<CardSet> sets,  String? error,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _SetsState():
return $default(_that.status,_that.sets,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewStatus status,  List<CardSet> sets,  String? error,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _SetsState() when $default != null:
return $default(_that.status,_that.sets,_that.error,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _SetsState implements SetsState {
  const _SetsState({this.status = ViewStatus.initial, final  List<CardSet> sets = const <CardSet>[], this.error, this.notice}): _sets = sets;
  

@override@JsonKey() final  ViewStatus status;
 final  List<CardSet> _sets;
@override@JsonKey() List<CardSet> get sets {
  if (_sets is EqualUnmodifiableListView) return _sets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sets);
}

@override final  String? error;
@override final  String? notice;

/// Create a copy of SetsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetsStateCopyWith<_SetsState> get copyWith => __$SetsStateCopyWithImpl<_SetsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetsState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._sets, _sets)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_sets),error,notice);

@override
String toString() {
  return 'SetsState(status: $status, sets: $sets, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$SetsStateCopyWith<$Res> implements $SetsStateCopyWith<$Res> {
  factory _$SetsStateCopyWith(_SetsState value, $Res Function(_SetsState) _then) = __$SetsStateCopyWithImpl;
@override @useResult
$Res call({
 ViewStatus status, List<CardSet> sets, String? error, String? notice
});




}
/// @nodoc
class __$SetsStateCopyWithImpl<$Res>
    implements _$SetsStateCopyWith<$Res> {
  __$SetsStateCopyWithImpl(this._self, this._then);

  final _SetsState _self;
  final $Res Function(_SetsState) _then;

/// Create a copy of SetsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? sets = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_SetsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,sets: null == sets ? _self._sets : sets // ignore: cast_nullable_to_non_nullable
as List<CardSet>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
