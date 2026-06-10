// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_player_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QuizPlayerState {

 QuizPhase get phase; Quiz? get quiz; int get index;/// Gecerli soruda secilen sik (null: henuz secilmedi).
 int? get selected; int get score; String? get error;
/// Create a copy of QuizPlayerState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizPlayerStateCopyWith<QuizPlayerState> get copyWith => _$QuizPlayerStateCopyWithImpl<QuizPlayerState>(this as QuizPlayerState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizPlayerState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.index, index) || other.index == index)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.score, score) || other.score == score)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,phase,quiz,index,selected,score,error);

@override
String toString() {
  return 'QuizPlayerState(phase: $phase, quiz: $quiz, index: $index, selected: $selected, score: $score, error: $error)';
}


}

/// @nodoc
abstract mixin class $QuizPlayerStateCopyWith<$Res>  {
  factory $QuizPlayerStateCopyWith(QuizPlayerState value, $Res Function(QuizPlayerState) _then) = _$QuizPlayerStateCopyWithImpl;
@useResult
$Res call({
 QuizPhase phase, Quiz? quiz, int index, int? selected, int score, String? error
});


$QuizCopyWith<$Res>? get quiz;

}
/// @nodoc
class _$QuizPlayerStateCopyWithImpl<$Res>
    implements $QuizPlayerStateCopyWith<$Res> {
  _$QuizPlayerStateCopyWithImpl(this._self, this._then);

  final QuizPlayerState _self;
  final $Res Function(QuizPlayerState) _then;

/// Create a copy of QuizPlayerState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? quiz = freezed,Object? index = null,Object? selected = freezed,Object? score = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as QuizPhase,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as Quiz?,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as int?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of QuizPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $QuizCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}
}


/// Adds pattern-matching-related methods to [QuizPlayerState].
extension QuizPlayerStatePatterns on QuizPlayerState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizPlayerState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizPlayerState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizPlayerState value)  $default,){
final _that = this;
switch (_that) {
case _QuizPlayerState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizPlayerState value)?  $default,){
final _that = this;
switch (_that) {
case _QuizPlayerState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( QuizPhase phase,  Quiz? quiz,  int index,  int? selected,  int score,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizPlayerState() when $default != null:
return $default(_that.phase,_that.quiz,_that.index,_that.selected,_that.score,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( QuizPhase phase,  Quiz? quiz,  int index,  int? selected,  int score,  String? error)  $default,) {final _that = this;
switch (_that) {
case _QuizPlayerState():
return $default(_that.phase,_that.quiz,_that.index,_that.selected,_that.score,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( QuizPhase phase,  Quiz? quiz,  int index,  int? selected,  int score,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _QuizPlayerState() when $default != null:
return $default(_that.phase,_that.quiz,_that.index,_that.selected,_that.score,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _QuizPlayerState extends QuizPlayerState {
  const _QuizPlayerState({this.phase = QuizPhase.loading, this.quiz, this.index = 0, this.selected, this.score = 0, this.error}): super._();
  

@override@JsonKey() final  QuizPhase phase;
@override final  Quiz? quiz;
@override@JsonKey() final  int index;
/// Gecerli soruda secilen sik (null: henuz secilmedi).
@override final  int? selected;
@override@JsonKey() final  int score;
@override final  String? error;

/// Create a copy of QuizPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizPlayerStateCopyWith<_QuizPlayerState> get copyWith => __$QuizPlayerStateCopyWithImpl<_QuizPlayerState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizPlayerState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.quiz, quiz) || other.quiz == quiz)&&(identical(other.index, index) || other.index == index)&&(identical(other.selected, selected) || other.selected == selected)&&(identical(other.score, score) || other.score == score)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,phase,quiz,index,selected,score,error);

@override
String toString() {
  return 'QuizPlayerState(phase: $phase, quiz: $quiz, index: $index, selected: $selected, score: $score, error: $error)';
}


}

/// @nodoc
abstract mixin class _$QuizPlayerStateCopyWith<$Res> implements $QuizPlayerStateCopyWith<$Res> {
  factory _$QuizPlayerStateCopyWith(_QuizPlayerState value, $Res Function(_QuizPlayerState) _then) = __$QuizPlayerStateCopyWithImpl;
@override @useResult
$Res call({
 QuizPhase phase, Quiz? quiz, int index, int? selected, int score, String? error
});


@override $QuizCopyWith<$Res>? get quiz;

}
/// @nodoc
class __$QuizPlayerStateCopyWithImpl<$Res>
    implements _$QuizPlayerStateCopyWith<$Res> {
  __$QuizPlayerStateCopyWithImpl(this._self, this._then);

  final _QuizPlayerState _self;
  final $Res Function(_QuizPlayerState) _then;

/// Create a copy of QuizPlayerState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? quiz = freezed,Object? index = null,Object? selected = freezed,Object? score = null,Object? error = freezed,}) {
  return _then(_QuizPlayerState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as QuizPhase,quiz: freezed == quiz ? _self.quiz : quiz // ignore: cast_nullable_to_non_nullable
as Quiz?,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as int?,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of QuizPlayerState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$QuizCopyWith<$Res>? get quiz {
    if (_self.quiz == null) {
    return null;
  }

  return $QuizCopyWith<$Res>(_self.quiz!, (value) {
    return _then(_self.copyWith(quiz: value));
  });
}
}

// dart format on
