// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generate_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GenerateState {

 GenerateKind get kind; bool get submitting; String? get error;/// Uretim baslatildiginda olusan set/quiz id'si (yonlendirme icin).
 String? get createdId; GenerateKind? get createdKind;
/// Create a copy of GenerateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenerateStateCopyWith<GenerateState> get copyWith => _$GenerateStateCopyWithImpl<GenerateState>(this as GenerateState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GenerateState&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.error, error) || other.error == error)&&(identical(other.createdId, createdId) || other.createdId == createdId)&&(identical(other.createdKind, createdKind) || other.createdKind == createdKind));
}


@override
int get hashCode => Object.hash(runtimeType,kind,submitting,error,createdId,createdKind);

@override
String toString() {
  return 'GenerateState(kind: $kind, submitting: $submitting, error: $error, createdId: $createdId, createdKind: $createdKind)';
}


}

/// @nodoc
abstract mixin class $GenerateStateCopyWith<$Res>  {
  factory $GenerateStateCopyWith(GenerateState value, $Res Function(GenerateState) _then) = _$GenerateStateCopyWithImpl;
@useResult
$Res call({
 GenerateKind kind, bool submitting, String? error, String? createdId, GenerateKind? createdKind
});




}
/// @nodoc
class _$GenerateStateCopyWithImpl<$Res>
    implements $GenerateStateCopyWith<$Res> {
  _$GenerateStateCopyWithImpl(this._self, this._then);

  final GenerateState _self;
  final $Res Function(GenerateState) _then;

/// Create a copy of GenerateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? submitting = null,Object? error = freezed,Object? createdId = freezed,Object? createdKind = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GenerateKind,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,createdId: freezed == createdId ? _self.createdId : createdId // ignore: cast_nullable_to_non_nullable
as String?,createdKind: freezed == createdKind ? _self.createdKind : createdKind // ignore: cast_nullable_to_non_nullable
as GenerateKind?,
  ));
}

}


/// Adds pattern-matching-related methods to [GenerateState].
extension GenerateStatePatterns on GenerateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GenerateState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GenerateState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GenerateState value)  $default,){
final _that = this;
switch (_that) {
case _GenerateState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GenerateState value)?  $default,){
final _that = this;
switch (_that) {
case _GenerateState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GenerateKind kind,  bool submitting,  String? error,  String? createdId,  GenerateKind? createdKind)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GenerateState() when $default != null:
return $default(_that.kind,_that.submitting,_that.error,_that.createdId,_that.createdKind);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GenerateKind kind,  bool submitting,  String? error,  String? createdId,  GenerateKind? createdKind)  $default,) {final _that = this;
switch (_that) {
case _GenerateState():
return $default(_that.kind,_that.submitting,_that.error,_that.createdId,_that.createdKind);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GenerateKind kind,  bool submitting,  String? error,  String? createdId,  GenerateKind? createdKind)?  $default,) {final _that = this;
switch (_that) {
case _GenerateState() when $default != null:
return $default(_that.kind,_that.submitting,_that.error,_that.createdId,_that.createdKind);case _:
  return null;

}
}

}

/// @nodoc


class _GenerateState implements GenerateState {
  const _GenerateState({this.kind = GenerateKind.cards, this.submitting = false, this.error, this.createdId, this.createdKind});
  

@override@JsonKey() final  GenerateKind kind;
@override@JsonKey() final  bool submitting;
@override final  String? error;
/// Uretim baslatildiginda olusan set/quiz id'si (yonlendirme icin).
@override final  String? createdId;
@override final  GenerateKind? createdKind;

/// Create a copy of GenerateState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GenerateStateCopyWith<_GenerateState> get copyWith => __$GenerateStateCopyWithImpl<_GenerateState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GenerateState&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.submitting, submitting) || other.submitting == submitting)&&(identical(other.error, error) || other.error == error)&&(identical(other.createdId, createdId) || other.createdId == createdId)&&(identical(other.createdKind, createdKind) || other.createdKind == createdKind));
}


@override
int get hashCode => Object.hash(runtimeType,kind,submitting,error,createdId,createdKind);

@override
String toString() {
  return 'GenerateState(kind: $kind, submitting: $submitting, error: $error, createdId: $createdId, createdKind: $createdKind)';
}


}

/// @nodoc
abstract mixin class _$GenerateStateCopyWith<$Res> implements $GenerateStateCopyWith<$Res> {
  factory _$GenerateStateCopyWith(_GenerateState value, $Res Function(_GenerateState) _then) = __$GenerateStateCopyWithImpl;
@override @useResult
$Res call({
 GenerateKind kind, bool submitting, String? error, String? createdId, GenerateKind? createdKind
});




}
/// @nodoc
class __$GenerateStateCopyWithImpl<$Res>
    implements _$GenerateStateCopyWith<$Res> {
  __$GenerateStateCopyWithImpl(this._self, this._then);

  final _GenerateState _self;
  final $Res Function(_GenerateState) _then;

/// Create a copy of GenerateState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? submitting = null,Object? error = freezed,Object? createdId = freezed,Object? createdKind = freezed,}) {
  return _then(_GenerateState(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as GenerateKind,submitting: null == submitting ? _self.submitting : submitting // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,createdId: freezed == createdId ? _self.createdId : createdId // ignore: cast_nullable_to_non_nullable
as String?,createdKind: freezed == createdKind ? _self.createdKind : createdKind // ignore: cast_nullable_to_non_nullable
as GenerateKind?,
  ));
}


}

// dart format on
