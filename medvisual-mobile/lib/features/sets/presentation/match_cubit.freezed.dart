// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'match_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MatchState {

/// DIP taramasi calisiyor (30-120 sn surebilir).
 bool get searching; bool get searched; List<Candidate> get candidates;/// Secim istegi gonderilen adayin path'i.
 String? get selectingPath;/// Kalici gorsel atanan guncel kart (basari sinyali).
 Flashcard? get selectedCard; String? get error;
/// Create a copy of MatchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MatchStateCopyWith<MatchState> get copyWith => _$MatchStateCopyWithImpl<MatchState>(this as MatchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MatchState&&(identical(other.searching, searching) || other.searching == searching)&&(identical(other.searched, searched) || other.searched == searched)&&const DeepCollectionEquality().equals(other.candidates, candidates)&&(identical(other.selectingPath, selectingPath) || other.selectingPath == selectingPath)&&(identical(other.selectedCard, selectedCard) || other.selectedCard == selectedCard)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,searching,searched,const DeepCollectionEquality().hash(candidates),selectingPath,selectedCard,error);

@override
String toString() {
  return 'MatchState(searching: $searching, searched: $searched, candidates: $candidates, selectingPath: $selectingPath, selectedCard: $selectedCard, error: $error)';
}


}

/// @nodoc
abstract mixin class $MatchStateCopyWith<$Res>  {
  factory $MatchStateCopyWith(MatchState value, $Res Function(MatchState) _then) = _$MatchStateCopyWithImpl;
@useResult
$Res call({
 bool searching, bool searched, List<Candidate> candidates, String? selectingPath, Flashcard? selectedCard, String? error
});


$FlashcardCopyWith<$Res>? get selectedCard;

}
/// @nodoc
class _$MatchStateCopyWithImpl<$Res>
    implements $MatchStateCopyWith<$Res> {
  _$MatchStateCopyWithImpl(this._self, this._then);

  final MatchState _self;
  final $Res Function(MatchState) _then;

/// Create a copy of MatchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? searching = null,Object? searched = null,Object? candidates = null,Object? selectingPath = freezed,Object? selectedCard = freezed,Object? error = freezed,}) {
  return _then(_self.copyWith(
searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,searched: null == searched ? _self.searched : searched // ignore: cast_nullable_to_non_nullable
as bool,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<Candidate>,selectingPath: freezed == selectingPath ? _self.selectingPath : selectingPath // ignore: cast_nullable_to_non_nullable
as String?,selectedCard: freezed == selectedCard ? _self.selectedCard : selectedCard // ignore: cast_nullable_to_non_nullable
as Flashcard?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of MatchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlashcardCopyWith<$Res>? get selectedCard {
    if (_self.selectedCard == null) {
    return null;
  }

  return $FlashcardCopyWith<$Res>(_self.selectedCard!, (value) {
    return _then(_self.copyWith(selectedCard: value));
  });
}
}


/// Adds pattern-matching-related methods to [MatchState].
extension MatchStatePatterns on MatchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MatchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MatchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MatchState value)  $default,){
final _that = this;
switch (_that) {
case _MatchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MatchState value)?  $default,){
final _that = this;
switch (_that) {
case _MatchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool searching,  bool searched,  List<Candidate> candidates,  String? selectingPath,  Flashcard? selectedCard,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MatchState() when $default != null:
return $default(_that.searching,_that.searched,_that.candidates,_that.selectingPath,_that.selectedCard,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool searching,  bool searched,  List<Candidate> candidates,  String? selectingPath,  Flashcard? selectedCard,  String? error)  $default,) {final _that = this;
switch (_that) {
case _MatchState():
return $default(_that.searching,_that.searched,_that.candidates,_that.selectingPath,_that.selectedCard,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool searching,  bool searched,  List<Candidate> candidates,  String? selectingPath,  Flashcard? selectedCard,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _MatchState() when $default != null:
return $default(_that.searching,_that.searched,_that.candidates,_that.selectingPath,_that.selectedCard,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _MatchState implements MatchState {
  const _MatchState({this.searching = false, this.searched = false, final  List<Candidate> candidates = const <Candidate>[], this.selectingPath, this.selectedCard, this.error}): _candidates = candidates;
  

/// DIP taramasi calisiyor (30-120 sn surebilir).
@override@JsonKey() final  bool searching;
@override@JsonKey() final  bool searched;
 final  List<Candidate> _candidates;
@override@JsonKey() List<Candidate> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}

/// Secim istegi gonderilen adayin path'i.
@override final  String? selectingPath;
/// Kalici gorsel atanan guncel kart (basari sinyali).
@override final  Flashcard? selectedCard;
@override final  String? error;

/// Create a copy of MatchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MatchStateCopyWith<_MatchState> get copyWith => __$MatchStateCopyWithImpl<_MatchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MatchState&&(identical(other.searching, searching) || other.searching == searching)&&(identical(other.searched, searched) || other.searched == searched)&&const DeepCollectionEquality().equals(other._candidates, _candidates)&&(identical(other.selectingPath, selectingPath) || other.selectingPath == selectingPath)&&(identical(other.selectedCard, selectedCard) || other.selectedCard == selectedCard)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,searching,searched,const DeepCollectionEquality().hash(_candidates),selectingPath,selectedCard,error);

@override
String toString() {
  return 'MatchState(searching: $searching, searched: $searched, candidates: $candidates, selectingPath: $selectingPath, selectedCard: $selectedCard, error: $error)';
}


}

/// @nodoc
abstract mixin class _$MatchStateCopyWith<$Res> implements $MatchStateCopyWith<$Res> {
  factory _$MatchStateCopyWith(_MatchState value, $Res Function(_MatchState) _then) = __$MatchStateCopyWithImpl;
@override @useResult
$Res call({
 bool searching, bool searched, List<Candidate> candidates, String? selectingPath, Flashcard? selectedCard, String? error
});


@override $FlashcardCopyWith<$Res>? get selectedCard;

}
/// @nodoc
class __$MatchStateCopyWithImpl<$Res>
    implements _$MatchStateCopyWith<$Res> {
  __$MatchStateCopyWithImpl(this._self, this._then);

  final _MatchState _self;
  final $Res Function(_MatchState) _then;

/// Create a copy of MatchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? searching = null,Object? searched = null,Object? candidates = null,Object? selectingPath = freezed,Object? selectedCard = freezed,Object? error = freezed,}) {
  return _then(_MatchState(
searching: null == searching ? _self.searching : searching // ignore: cast_nullable_to_non_nullable
as bool,searched: null == searched ? _self.searched : searched // ignore: cast_nullable_to_non_nullable
as bool,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<Candidate>,selectingPath: freezed == selectingPath ? _self.selectingPath : selectingPath // ignore: cast_nullable_to_non_nullable
as String?,selectedCard: freezed == selectedCard ? _self.selectedCard : selectedCard // ignore: cast_nullable_to_non_nullable
as Flashcard?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of MatchState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlashcardCopyWith<$Res>? get selectedCard {
    if (_self.selectedCard == null) {
    return null;
  }

  return $FlashcardCopyWith<$Res>(_self.selectedCard!, (value) {
    return _then(_self.copyWith(selectedCard: value));
  });
}
}

// dart format on
