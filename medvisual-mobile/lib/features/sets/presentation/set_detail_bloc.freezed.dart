// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'set_detail_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SetDetailState {

 ViewStatus get status; CardSet? get set; String? get error; String? get notice;
/// Create a copy of SetDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SetDetailStateCopyWith<SetDetailState> get copyWith => _$SetDetailStateCopyWithImpl<SetDetailState>(this as SetDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SetDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.set, set) || other.set == set)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,set,error,notice);

@override
String toString() {
  return 'SetDetailState(status: $status, set: $set, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class $SetDetailStateCopyWith<$Res>  {
  factory $SetDetailStateCopyWith(SetDetailState value, $Res Function(SetDetailState) _then) = _$SetDetailStateCopyWithImpl;
@useResult
$Res call({
 ViewStatus status, CardSet? set, String? error, String? notice
});


$CardSetCopyWith<$Res>? get set;

}
/// @nodoc
class _$SetDetailStateCopyWithImpl<$Res>
    implements $SetDetailStateCopyWith<$Res> {
  _$SetDetailStateCopyWithImpl(this._self, this._then);

  final SetDetailState _self;
  final $Res Function(SetDetailState) _then;

/// Create a copy of SetDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? set = freezed,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,set: freezed == set ? _self.set : set // ignore: cast_nullable_to_non_nullable
as CardSet?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SetDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardSetCopyWith<$Res>? get set {
    if (_self.set == null) {
    return null;
  }

  return $CardSetCopyWith<$Res>(_self.set!, (value) {
    return _then(_self.copyWith(set: value));
  });
}
}


/// Adds pattern-matching-related methods to [SetDetailState].
extension SetDetailStatePatterns on SetDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SetDetailState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SetDetailState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SetDetailState value)  $default,){
final _that = this;
switch (_that) {
case _SetDetailState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SetDetailState value)?  $default,){
final _that = this;
switch (_that) {
case _SetDetailState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewStatus status,  CardSet? set,  String? error,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SetDetailState() when $default != null:
return $default(_that.status,_that.set,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewStatus status,  CardSet? set,  String? error,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _SetDetailState():
return $default(_that.status,_that.set,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewStatus status,  CardSet? set,  String? error,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _SetDetailState() when $default != null:
return $default(_that.status,_that.set,_that.error,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _SetDetailState implements SetDetailState {
  const _SetDetailState({this.status = ViewStatus.initial, this.set, this.error, this.notice});
  

@override@JsonKey() final  ViewStatus status;
@override final  CardSet? set;
@override final  String? error;
@override final  String? notice;

/// Create a copy of SetDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SetDetailStateCopyWith<_SetDetailState> get copyWith => __$SetDetailStateCopyWithImpl<_SetDetailState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SetDetailState&&(identical(other.status, status) || other.status == status)&&(identical(other.set, set) || other.set == set)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,set,error,notice);

@override
String toString() {
  return 'SetDetailState(status: $status, set: $set, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$SetDetailStateCopyWith<$Res> implements $SetDetailStateCopyWith<$Res> {
  factory _$SetDetailStateCopyWith(_SetDetailState value, $Res Function(_SetDetailState) _then) = __$SetDetailStateCopyWithImpl;
@override @useResult
$Res call({
 ViewStatus status, CardSet? set, String? error, String? notice
});


@override $CardSetCopyWith<$Res>? get set;

}
/// @nodoc
class __$SetDetailStateCopyWithImpl<$Res>
    implements _$SetDetailStateCopyWith<$Res> {
  __$SetDetailStateCopyWithImpl(this._self, this._then);

  final _SetDetailState _self;
  final $Res Function(_SetDetailState) _then;

/// Create a copy of SetDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? set = freezed,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_SetDetailState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,set: freezed == set ? _self.set : set // ignore: cast_nullable_to_non_nullable
as CardSet?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SetDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardSetCopyWith<$Res>? get set {
    if (_self.set == null) {
    return null;
  }

  return $CardSetCopyWith<$Res>(_self.set!, (value) {
    return _then(_self.copyWith(set: value));
  });
}
}

// dart format on
