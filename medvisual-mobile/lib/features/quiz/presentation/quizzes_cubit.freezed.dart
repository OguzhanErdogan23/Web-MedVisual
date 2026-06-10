// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quizzes_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuizzesState {

 ViewStatus get status; List<Quiz> get quizzes; String? get error; String? get notice;
/// Create a copy of QuizzesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizzesStateCopyWith<QuizzesState> get copyWith => _$QuizzesStateCopyWithImpl<QuizzesState>(this as QuizzesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizzesState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.quizzes, quizzes)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(quizzes),error,notice);

@override
String toString() {
  return 'QuizzesState(status: $status, quizzes: $quizzes, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class $QuizzesStateCopyWith<$Res>  {
  factory $QuizzesStateCopyWith(QuizzesState value, $Res Function(QuizzesState) _then) = _$QuizzesStateCopyWithImpl;
@useResult
$Res call({
 ViewStatus status, List<Quiz> quizzes, String? error, String? notice
});




}
/// @nodoc
class _$QuizzesStateCopyWithImpl<$Res>
    implements $QuizzesStateCopyWith<$Res> {
  _$QuizzesStateCopyWithImpl(this._self, this._then);

  final QuizzesState _self;
  final $Res Function(QuizzesState) _then;

/// Create a copy of QuizzesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? quizzes = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as List<Quiz>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizzesState].
extension QuizzesStatePatterns on QuizzesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizzesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizzesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizzesState value)  $default,){
final _that = this;
switch (_that) {
case _QuizzesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizzesState value)?  $default,){
final _that = this;
switch (_that) {
case _QuizzesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ViewStatus status,  List<Quiz> quizzes,  String? error,  String? notice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizzesState() when $default != null:
return $default(_that.status,_that.quizzes,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ViewStatus status,  List<Quiz> quizzes,  String? error,  String? notice)  $default,) {final _that = this;
switch (_that) {
case _QuizzesState():
return $default(_that.status,_that.quizzes,_that.error,_that.notice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ViewStatus status,  List<Quiz> quizzes,  String? error,  String? notice)?  $default,) {final _that = this;
switch (_that) {
case _QuizzesState() when $default != null:
return $default(_that.status,_that.quizzes,_that.error,_that.notice);case _:
  return null;

}
}

}

/// @nodoc


class _QuizzesState implements QuizzesState {
  const _QuizzesState({this.status = ViewStatus.initial, final  List<Quiz> quizzes = const <Quiz>[], this.error, this.notice}): _quizzes = quizzes;
  

@override@JsonKey() final  ViewStatus status;
 final  List<Quiz> _quizzes;
@override@JsonKey() List<Quiz> get quizzes {
  if (_quizzes is EqualUnmodifiableListView) return _quizzes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_quizzes);
}

@override final  String? error;
@override final  String? notice;

/// Create a copy of QuizzesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizzesStateCopyWith<_QuizzesState> get copyWith => __$QuizzesStateCopyWithImpl<_QuizzesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizzesState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._quizzes, _quizzes)&&(identical(other.error, error) || other.error == error)&&(identical(other.notice, notice) || other.notice == notice));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_quizzes),error,notice);

@override
String toString() {
  return 'QuizzesState(status: $status, quizzes: $quizzes, error: $error, notice: $notice)';
}


}

/// @nodoc
abstract mixin class _$QuizzesStateCopyWith<$Res> implements $QuizzesStateCopyWith<$Res> {
  factory _$QuizzesStateCopyWith(_QuizzesState value, $Res Function(_QuizzesState) _then) = __$QuizzesStateCopyWithImpl;
@override @useResult
$Res call({
 ViewStatus status, List<Quiz> quizzes, String? error, String? notice
});




}
/// @nodoc
class __$QuizzesStateCopyWithImpl<$Res>
    implements _$QuizzesStateCopyWith<$Res> {
  __$QuizzesStateCopyWithImpl(this._self, this._then);

  final _QuizzesState _self;
  final $Res Function(_QuizzesState) _then;

/// Create a copy of QuizzesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? quizzes = null,Object? error = freezed,Object? notice = freezed,}) {
  return _then(_QuizzesState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ViewStatus,quizzes: null == quizzes ? _self._quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as List<Quiz>,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notice: freezed == notice ? _self.notice : notice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
