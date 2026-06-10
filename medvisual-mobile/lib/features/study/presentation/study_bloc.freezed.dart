// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StudyState {

 StudyPhase get phase; List<DueCard> get queue; int get index; bool get flipped;/// Not -> cevap sayisi (oturum ozeti icin).
 Map<Grade, int> get gradeCounts;/// Sunucuya yazilamayan cevap sayisi (bilgilendirme).
 int get syncFailures; int get newCount; String? get error;
/// Create a copy of StudyState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyStateCopyWith<StudyState> get copyWith => _$StudyStateCopyWithImpl<StudyState>(this as StudyState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other.queue, queue)&&(identical(other.index, index) || other.index == index)&&(identical(other.flipped, flipped) || other.flipped == flipped)&&const DeepCollectionEquality().equals(other.gradeCounts, gradeCounts)&&(identical(other.syncFailures, syncFailures) || other.syncFailures == syncFailures)&&(identical(other.newCount, newCount) || other.newCount == newCount)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(queue),index,flipped,const DeepCollectionEquality().hash(gradeCounts),syncFailures,newCount,error);

@override
String toString() {
  return 'StudyState(phase: $phase, queue: $queue, index: $index, flipped: $flipped, gradeCounts: $gradeCounts, syncFailures: $syncFailures, newCount: $newCount, error: $error)';
}


}

/// @nodoc
abstract mixin class $StudyStateCopyWith<$Res>  {
  factory $StudyStateCopyWith(StudyState value, $Res Function(StudyState) _then) = _$StudyStateCopyWithImpl;
@useResult
$Res call({
 StudyPhase phase, List<DueCard> queue, int index, bool flipped, Map<Grade, int> gradeCounts, int syncFailures, int newCount, String? error
});




}
/// @nodoc
class _$StudyStateCopyWithImpl<$Res>
    implements $StudyStateCopyWith<$Res> {
  _$StudyStateCopyWithImpl(this._self, this._then);

  final StudyState _self;
  final $Res Function(StudyState) _then;

/// Create a copy of StudyState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? queue = null,Object? index = null,Object? flipped = null,Object? gradeCounts = null,Object? syncFailures = null,Object? newCount = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as StudyPhase,queue: null == queue ? _self.queue : queue // ignore: cast_nullable_to_non_nullable
as List<DueCard>,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,flipped: null == flipped ? _self.flipped : flipped // ignore: cast_nullable_to_non_nullable
as bool,gradeCounts: null == gradeCounts ? _self.gradeCounts : gradeCounts // ignore: cast_nullable_to_non_nullable
as Map<Grade, int>,syncFailures: null == syncFailures ? _self.syncFailures : syncFailures // ignore: cast_nullable_to_non_nullable
as int,newCount: null == newCount ? _self.newCount : newCount // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudyState].
extension StudyStatePatterns on StudyState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyState value)  $default,){
final _that = this;
switch (_that) {
case _StudyState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyState value)?  $default,){
final _that = this;
switch (_that) {
case _StudyState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StudyPhase phase,  List<DueCard> queue,  int index,  bool flipped,  Map<Grade, int> gradeCounts,  int syncFailures,  int newCount,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyState() when $default != null:
return $default(_that.phase,_that.queue,_that.index,_that.flipped,_that.gradeCounts,_that.syncFailures,_that.newCount,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StudyPhase phase,  List<DueCard> queue,  int index,  bool flipped,  Map<Grade, int> gradeCounts,  int syncFailures,  int newCount,  String? error)  $default,) {final _that = this;
switch (_that) {
case _StudyState():
return $default(_that.phase,_that.queue,_that.index,_that.flipped,_that.gradeCounts,_that.syncFailures,_that.newCount,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StudyPhase phase,  List<DueCard> queue,  int index,  bool flipped,  Map<Grade, int> gradeCounts,  int syncFailures,  int newCount,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _StudyState() when $default != null:
return $default(_that.phase,_that.queue,_that.index,_that.flipped,_that.gradeCounts,_that.syncFailures,_that.newCount,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _StudyState extends StudyState {
  const _StudyState({this.phase = StudyPhase.loading, final  List<DueCard> queue = const <DueCard>[], this.index = 0, this.flipped = false, final  Map<Grade, int> gradeCounts = const <Grade, int>{}, this.syncFailures = 0, this.newCount = 0, this.error}): _queue = queue,_gradeCounts = gradeCounts,super._();
  

@override@JsonKey() final  StudyPhase phase;
 final  List<DueCard> _queue;
@override@JsonKey() List<DueCard> get queue {
  if (_queue is EqualUnmodifiableListView) return _queue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_queue);
}

@override@JsonKey() final  int index;
@override@JsonKey() final  bool flipped;
/// Not -> cevap sayisi (oturum ozeti icin).
 final  Map<Grade, int> _gradeCounts;
/// Not -> cevap sayisi (oturum ozeti icin).
@override@JsonKey() Map<Grade, int> get gradeCounts {
  if (_gradeCounts is EqualUnmodifiableMapView) return _gradeCounts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_gradeCounts);
}

/// Sunucuya yazilamayan cevap sayisi (bilgilendirme).
@override@JsonKey() final  int syncFailures;
@override@JsonKey() final  int newCount;
@override final  String? error;

/// Create a copy of StudyState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyStateCopyWith<_StudyState> get copyWith => __$StudyStateCopyWithImpl<_StudyState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyState&&(identical(other.phase, phase) || other.phase == phase)&&const DeepCollectionEquality().equals(other._queue, _queue)&&(identical(other.index, index) || other.index == index)&&(identical(other.flipped, flipped) || other.flipped == flipped)&&const DeepCollectionEquality().equals(other._gradeCounts, _gradeCounts)&&(identical(other.syncFailures, syncFailures) || other.syncFailures == syncFailures)&&(identical(other.newCount, newCount) || other.newCount == newCount)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,phase,const DeepCollectionEquality().hash(_queue),index,flipped,const DeepCollectionEquality().hash(_gradeCounts),syncFailures,newCount,error);

@override
String toString() {
  return 'StudyState(phase: $phase, queue: $queue, index: $index, flipped: $flipped, gradeCounts: $gradeCounts, syncFailures: $syncFailures, newCount: $newCount, error: $error)';
}


}

/// @nodoc
abstract mixin class _$StudyStateCopyWith<$Res> implements $StudyStateCopyWith<$Res> {
  factory _$StudyStateCopyWith(_StudyState value, $Res Function(_StudyState) _then) = __$StudyStateCopyWithImpl;
@override @useResult
$Res call({
 StudyPhase phase, List<DueCard> queue, int index, bool flipped, Map<Grade, int> gradeCounts, int syncFailures, int newCount, String? error
});




}
/// @nodoc
class __$StudyStateCopyWithImpl<$Res>
    implements _$StudyStateCopyWith<$Res> {
  __$StudyStateCopyWithImpl(this._self, this._then);

  final _StudyState _self;
  final $Res Function(_StudyState) _then;

/// Create a copy of StudyState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? queue = null,Object? index = null,Object? flipped = null,Object? gradeCounts = null,Object? syncFailures = null,Object? newCount = null,Object? error = freezed,}) {
  return _then(_StudyState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as StudyPhase,queue: null == queue ? _self._queue : queue // ignore: cast_nullable_to_non_nullable
as List<DueCard>,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,flipped: null == flipped ? _self.flipped : flipped // ignore: cast_nullable_to_non_nullable
as bool,gradeCounts: null == gradeCounts ? _self._gradeCounts : gradeCounts // ignore: cast_nullable_to_non_nullable
as Map<Grade, int>,syncFailures: null == syncFailures ? _self.syncFailures : syncFailures // ignore: cast_nullable_to_non_nullable
as int,newCount: null == newCount ? _self.newCount : newCount // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
