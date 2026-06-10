// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {

 ViewStatus get status; Profile? get profile; bool get saving; String? get error; String? get notice;
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsStateCopyWith<SettingsState> get copyWith => _$SettingsStateCopyWithImpl<SettingsState>(this as SettingsState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,profile,saving,error,notice);

@override
String toString() {
  return 'SettingsState(status: $status, profile: $profile, saving: $saving, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class $SettingsStateCopyWith<$Res>  {
  factory $SettingsStateCopyWith(SettingsState value, $Res Function(SettingsState) _then) = _$SettingsStateCopyWithImpl;
@useResult
$Res call({
 ViewStatus status, Profile? profile, bool saving, String? error, String? notice
});


$ProfileCopyWith<$Res>? get profile;

}
/// @nodoc
class _$SettingsStateCopyWithImpl<$Res>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._self, this._then);

  final SettingsState _self;
  final $Res Function(SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? profile = freezed,Object? saving = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Profile?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SettingsState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SettingsState value)  $default,){
final _that = this;
switch (_that) {
case _SettingsState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SettingsState value)?  $default,){
final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewStatus status,  Profile? profile,  bool saving,  String? error,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.status,_that.profile,_that.saving,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewStatus status,  Profile? profile,  bool saving,  String? error,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _SettingsState():
return $default(_that.status,_that.profile,_that.saving,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewStatus status,  Profile? profile,  bool saving,  String? error,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _SettingsState() when $default != null:
return $default(_that.status,_that.profile,_that.saving,_that.error,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _SettingsState implements SettingsState {
  const _SettingsState({this.status = ViewStatus.initial, this.profile, this.saving = false, this.error, this.notice});
  

@override@JsonKey() final  ViewStatus status;
@override final  Profile? profile;
@override@JsonKey() final  bool saving;
@override final  String? error;
@override final  String? notice;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SettingsStateCopyWith<_SettingsState> get copyWith => __$SettingsStateCopyWithImpl<_SettingsState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SettingsState&&(identical(other.status, status) || other.status == status)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,profile,saving,error,notice);

@override
String toString() {
  return 'SettingsState(status: $status, profile: $profile, saving: $saving, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$SettingsStateCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory _$SettingsStateCopyWith(_SettingsState value, $Res Function(_SettingsState) _then) = __$SettingsStateCopyWithImpl;
@override @useResult
$Res call({
 ViewStatus status, Profile? profile, bool saving, String? error, String? notice
});


@override $ProfileCopyWith<$Res>? get profile;

}
/// @nodoc
class __$SettingsStateCopyWithImpl<$Res>
    implements _$SettingsStateCopyWith<$Res> {
  __$SettingsStateCopyWithImpl(this._self, this._then);

  final _SettingsState _self;
  final $Res Function(_SettingsState) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? profile = freezed,Object? saving = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_SettingsState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as Profile?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfileCopyWith<$Res>? get profile {
    if (_self.profile == null) {
    return null;
  }

  return $ProfileCopyWith<$Res>(_self.profile!, (value) {
    return _then(_self.copyWith(profile: value));
  });
}
}

// dart format on
