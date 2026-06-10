// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DueCard {

 Flashcard get card; ReviewState? get review;
/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DueCardCopyWith<DueCard> get copyWith => _$DueCardCopyWithImpl<DueCard>(this as DueCard, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DueCard&&(identical(other.card, card) || other.card == card)&&(identical(other.review, review) || other.review == review));
}


@override
int get hashCode => Object.hash(runtimeType,card,review);

@override
String toString() {
  return 'DueCard(card: $card, review: $review)';
}


}

/// @nodoc
abstract mixin class $DueCardCopyWith<$Res>  {
  factory $DueCardCopyWith(DueCard value, $Res Function(DueCard) _then) = _$DueCardCopyWithImpl;
@useResult
$Res call({
 Flashcard card, ReviewState? review
});


$FlashcardCopyWith<$Res> get card;$ReviewStateCopyWith<$Res>? get review;

}
/// @nodoc
class _$DueCardCopyWithImpl<$Res>
    implements $DueCardCopyWith<$Res> {
  _$DueCardCopyWithImpl(this._self, this._then);

  final DueCard _self;
  final $Res Function(DueCard) _then;

/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? card = null,Object? review = freezed,}) {
  return _then(_self.copyWith(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as Flashcard,review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as ReviewState?,
  ));
}
/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlashcardCopyWith<$Res> get card {
  
  return $FlashcardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewStateCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewStateCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}


/// Adds pattern-matching-related methods to [DueCard].
extension DueCardPatterns on DueCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DueCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DueCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DueCard value)  $default,){
final _that = this;
switch (_that) {
case _DueCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DueCard value)?  $default,){
final _that = this;
switch (_that) {
case _DueCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Flashcard card,  ReviewState? review)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DueCard() when $default != null:
return $default(_that.card,_that.review);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Flashcard card,  ReviewState? review)  $default,) {final _that = this;
switch (_that) {
case _DueCard():
return $default(_that.card,_that.review);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Flashcard card,  ReviewState? review)?  $default,) {final _that = this;
switch (_that) {
case _DueCard() when $default != null:
return $default(_that.card,_that.review);case _:
  return null;

}
}

}

/// @nodoc


class _DueCard implements DueCard {
  const _DueCard({required this.card, this.review});
  

@override final  Flashcard card;
@override final  ReviewState? review;

/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DueCardCopyWith<_DueCard> get copyWith => __$DueCardCopyWithImpl<_DueCard>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DueCard&&(identical(other.card, card) || other.card == card)&&(identical(other.review, review) || other.review == review));
}


@override
int get hashCode => Object.hash(runtimeType,card,review);

@override
String toString() {
  return 'DueCard(card: $card, review: $review)';
}


}

/// @nodoc
abstract mixin class _$DueCardCopyWith<$Res> implements $DueCardCopyWith<$Res> {
  factory _$DueCardCopyWith(_DueCard value, $Res Function(_DueCard) _then) = __$DueCardCopyWithImpl;
@override @useResult
$Res call({
 Flashcard card, ReviewState? review
});


@override $FlashcardCopyWith<$Res> get card;@override $ReviewStateCopyWith<$Res>? get review;

}
/// @nodoc
class __$DueCardCopyWithImpl<$Res>
    implements _$DueCardCopyWith<$Res> {
  __$DueCardCopyWithImpl(this._self, this._then);

  final _DueCard _self;
  final $Res Function(_DueCard) _then;

/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? card = null,Object? review = freezed,}) {
  return _then(_DueCard(
card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as Flashcard,review: freezed == review ? _self.review : review // ignore: cast_nullable_to_non_nullable
as ReviewState?,
  ));
}

/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlashcardCopyWith<$Res> get card {
  
  return $FlashcardCopyWith<$Res>(_self.card, (value) {
    return _then(_self.copyWith(card: value));
  });
}/// Create a copy of DueCard
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewStateCopyWith<$Res>? get review {
    if (_self.review == null) {
    return null;
  }

  return $ReviewStateCopyWith<$Res>(_self.review!, (value) {
    return _then(_self.copyWith(review: value));
  });
}
}

/// @nodoc
mixin _$DueResult {

 List<DueCard> get cards; int get totalDue; int get newCount;
/// Create a copy of DueResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DueResultCopyWith<DueResult> get copyWith => _$DueResultCopyWithImpl<DueResult>(this as DueResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DueResult&&const DeepCollectionEquality().equals(other.cards, cards)&&(identical(other.totalDue, totalDue) || other.totalDue == totalDue)&&(identical(other.newCount, newCount) || other.newCount == newCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(cards),totalDue,newCount);

@override
String toString() {
  return 'DueResult(cards: $cards, totalDue: $totalDue, newCount: $newCount)';
}


}

/// @nodoc
abstract mixin class $DueResultCopyWith<$Res>  {
  factory $DueResultCopyWith(DueResult value, $Res Function(DueResult) _then) = _$DueResultCopyWithImpl;
@useResult
$Res call({
 List<DueCard> cards, int totalDue, int newCount
});




}
/// @nodoc
class _$DueResultCopyWithImpl<$Res>
    implements $DueResultCopyWith<$Res> {
  _$DueResultCopyWithImpl(this._self, this._then);

  final DueResult _self;
  final $Res Function(DueResult) _then;

/// Create a copy of DueResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cards = null,Object? totalDue = null,Object? newCount = null,}) {
  return _then(_self.copyWith(
cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as List<DueCard>,totalDue: null == totalDue ? _self.totalDue : totalDue // ignore: cast_nullable_to_non_nullable
as int,newCount: null == newCount ? _self.newCount : newCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DueResult].
extension DueResultPatterns on DueResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DueResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DueResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DueResult value)  $default,){
final _that = this;
switch (_that) {
case _DueResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DueResult value)?  $default,){
final _that = this;
switch (_that) {
case _DueResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<DueCard> cards,  int totalDue,  int newCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DueResult() when $default != null:
return $default(_that.cards,_that.totalDue,_that.newCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<DueCard> cards,  int totalDue,  int newCount)  $default,) {final _that = this;
switch (_that) {
case _DueResult():
return $default(_that.cards,_that.totalDue,_that.newCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<DueCard> cards,  int totalDue,  int newCount)?  $default,) {final _that = this;
switch (_that) {
case _DueResult() when $default != null:
return $default(_that.cards,_that.totalDue,_that.newCount);case _:
  return null;

}
}

}

/// @nodoc


class _DueResult implements DueResult {
  const _DueResult({final  List<DueCard> cards = const <DueCard>[], this.totalDue = 0, this.newCount = 0}): _cards = cards;
  

 final  List<DueCard> _cards;
@override@JsonKey() List<DueCard> get cards {
  if (_cards is EqualUnmodifiableListView) return _cards;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cards);
}

@override@JsonKey() final  int totalDue;
@override@JsonKey() final  int newCount;

/// Create a copy of DueResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DueResultCopyWith<_DueResult> get copyWith => __$DueResultCopyWithImpl<_DueResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DueResult&&const DeepCollectionEquality().equals(other._cards, _cards)&&(identical(other.totalDue, totalDue) || other.totalDue == totalDue)&&(identical(other.newCount, newCount) || other.newCount == newCount));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_cards),totalDue,newCount);

@override
String toString() {
  return 'DueResult(cards: $cards, totalDue: $totalDue, newCount: $newCount)';
}


}

/// @nodoc
abstract mixin class _$DueResultCopyWith<$Res> implements $DueResultCopyWith<$Res> {
  factory _$DueResultCopyWith(_DueResult value, $Res Function(_DueResult) _then) = __$DueResultCopyWithImpl;
@override @useResult
$Res call({
 List<DueCard> cards, int totalDue, int newCount
});




}
/// @nodoc
class __$DueResultCopyWithImpl<$Res>
    implements _$DueResultCopyWith<$Res> {
  __$DueResultCopyWithImpl(this._self, this._then);

  final _DueResult _self;
  final $Res Function(_DueResult) _then;

/// Create a copy of DueResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cards = null,Object? totalDue = null,Object? newCount = null,}) {
  return _then(_DueResult(
cards: null == cards ? _self._cards : cards // ignore: cast_nullable_to_non_nullable
as List<DueCard>,totalDue: null == totalDue ? _self.totalDue : totalDue // ignore: cast_nullable_to_non_nullable
as int,newCount: null == newCount ? _self.newCount : newCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StudyStats {

 int get documents; int get sets; int get cards; int get quizzes; int get dueNow; int get studiedCards;
/// Create a copy of StudyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyStatsCopyWith<StudyStats> get copyWith => _$StudyStatsCopyWithImpl<StudyStats>(this as StudyStats, _$identity);

  /// Serializes this StudyStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyStats&&(identical(other.documents, documents) || other.documents == documents)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.cards, cards) || other.cards == cards)&&(identical(other.quizzes, quizzes) || other.quizzes == quizzes)&&(identical(other.dueNow, dueNow) || other.dueNow == dueNow)&&(identical(other.studiedCards, studiedCards) || other.studiedCards == studiedCards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documents,sets,cards,quizzes,dueNow,studiedCards);

@override
String toString() {
  return 'StudyStats(documents: $documents, sets: $sets, cards: $cards, quizzes: $quizzes, dueNow: $dueNow, studiedCards: $studiedCards)';
}


}

/// @nodoc
abstract mixin class $StudyStatsCopyWith<$Res>  {
  factory $StudyStatsCopyWith(StudyStats value, $Res Function(StudyStats) _then) = _$StudyStatsCopyWithImpl;
@useResult
$Res call({
 int documents, int sets, int cards, int quizzes, int dueNow, int studiedCards
});




}
/// @nodoc
class _$StudyStatsCopyWithImpl<$Res>
    implements $StudyStatsCopyWith<$Res> {
  _$StudyStatsCopyWithImpl(this._self, this._then);

  final StudyStats _self;
  final $Res Function(StudyStats) _then;

/// Create a copy of StudyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documents = null,Object? sets = null,Object? cards = null,Object? quizzes = null,Object? dueNow = null,Object? studiedCards = null,}) {
  return _then(_self.copyWith(
documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as int,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as int,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as int,dueNow: null == dueNow ? _self.dueNow : dueNow // ignore: cast_nullable_to_non_nullable
as int,studiedCards: null == studiedCards ? _self.studiedCards : studiedCards // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StudyStats].
extension StudyStatsPatterns on StudyStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyStats value)  $default,){
final _that = this;
switch (_that) {
case _StudyStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyStats value)?  $default,){
final _that = this;
switch (_that) {
case _StudyStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int documents,  int sets,  int cards,  int quizzes,  int dueNow,  int studiedCards)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyStats() when $default != null:
return $default(_that.documents,_that.sets,_that.cards,_that.quizzes,_that.dueNow,_that.studiedCards);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int documents,  int sets,  int cards,  int quizzes,  int dueNow,  int studiedCards)  $default,) {final _that = this;
switch (_that) {
case _StudyStats():
return $default(_that.documents,_that.sets,_that.cards,_that.quizzes,_that.dueNow,_that.studiedCards);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int documents,  int sets,  int cards,  int quizzes,  int dueNow,  int studiedCards)?  $default,) {final _that = this;
switch (_that) {
case _StudyStats() when $default != null:
return $default(_that.documents,_that.sets,_that.cards,_that.quizzes,_that.dueNow,_that.studiedCards);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudyStats implements StudyStats {
  const _StudyStats({this.documents = 0, this.sets = 0, this.cards = 0, this.quizzes = 0, this.dueNow = 0, this.studiedCards = 0});
  factory _StudyStats.fromJson(Map<String, dynamic> json) => _$StudyStatsFromJson(json);

@override@JsonKey() final  int documents;
@override@JsonKey() final  int sets;
@override@JsonKey() final  int cards;
@override@JsonKey() final  int quizzes;
@override@JsonKey() final  int dueNow;
@override@JsonKey() final  int studiedCards;

/// Create a copy of StudyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyStatsCopyWith<_StudyStats> get copyWith => __$StudyStatsCopyWithImpl<_StudyStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudyStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyStats&&(identical(other.documents, documents) || other.documents == documents)&&(identical(other.sets, sets) || other.sets == sets)&&(identical(other.cards, cards) || other.cards == cards)&&(identical(other.quizzes, quizzes) || other.quizzes == quizzes)&&(identical(other.dueNow, dueNow) || other.dueNow == dueNow)&&(identical(other.studiedCards, studiedCards) || other.studiedCards == studiedCards));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,documents,sets,cards,quizzes,dueNow,studiedCards);

@override
String toString() {
  return 'StudyStats(documents: $documents, sets: $sets, cards: $cards, quizzes: $quizzes, dueNow: $dueNow, studiedCards: $studiedCards)';
}


}

/// @nodoc
abstract mixin class _$StudyStatsCopyWith<$Res> implements $StudyStatsCopyWith<$Res> {
  factory _$StudyStatsCopyWith(_StudyStats value, $Res Function(_StudyStats) _then) = __$StudyStatsCopyWithImpl;
@override @useResult
$Res call({
 int documents, int sets, int cards, int quizzes, int dueNow, int studiedCards
});




}
/// @nodoc
class __$StudyStatsCopyWithImpl<$Res>
    implements _$StudyStatsCopyWith<$Res> {
  __$StudyStatsCopyWithImpl(this._self, this._then);

  final _StudyStats _self;
  final $Res Function(_StudyStats) _then;

/// Create a copy of StudyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documents = null,Object? sets = null,Object? cards = null,Object? quizzes = null,Object? dueNow = null,Object? studiedCards = null,}) {
  return _then(_StudyStats(
documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as int,sets: null == sets ? _self.sets : sets // ignore: cast_nullable_to_non_nullable
as int,cards: null == cards ? _self.cards : cards // ignore: cast_nullable_to_non_nullable
as int,quizzes: null == quizzes ? _self.quizzes : quizzes // ignore: cast_nullable_to_non_nullable
as int,dueNow: null == dueNow ? _self.dueNow : dueNow // ignore: cast_nullable_to_non_nullable
as int,studiedCards: null == studiedCards ? _self.studiedCards : studiedCards // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
