// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'study_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StudyDay {

 String get date; int get total; int get correct;
/// Create a copy of StudyDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyDayCopyWith<StudyDay> get copyWith => _$StudyDayCopyWithImpl<StudyDay>(this as StudyDay, _$identity);

  /// Serializes this StudyDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyDay&&(identical(other.date, date) || other.date == date)&&(identical(other.total, total) || other.total == total)&&(identical(other.correct, correct) || other.correct == correct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,total,correct);

@override
String toString() {
  return 'StudyDay(date: $date, total: $total, correct: $correct)';
}


}

/// @nodoc
abstract mixin class $StudyDayCopyWith<$Res>  {
  factory $StudyDayCopyWith(StudyDay value, $Res Function(StudyDay) _then) = _$StudyDayCopyWithImpl;
@useResult
$Res call({
 String date, int total, int correct
});




}
/// @nodoc
class _$StudyDayCopyWithImpl<$Res>
    implements $StudyDayCopyWith<$Res> {
  _$StudyDayCopyWithImpl(this._self, this._then);

  final StudyDay _self;
  final $Res Function(StudyDay) _then;

/// Create a copy of StudyDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? total = null,Object? correct = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StudyDay].
extension StudyDayPatterns on StudyDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyDay value)  $default,){
final _that = this;
switch (_that) {
case _StudyDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyDay value)?  $default,){
final _that = this;
switch (_that) {
case _StudyDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int total,  int correct)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyDay() when $default != null:
return $default(_that.date,_that.total,_that.correct);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int total,  int correct)  $default,) {final _that = this;
switch (_that) {
case _StudyDay():
return $default(_that.date,_that.total,_that.correct);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int total,  int correct)?  $default,) {final _that = this;
switch (_that) {
case _StudyDay() when $default != null:
return $default(_that.date,_that.total,_that.correct);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudyDay implements StudyDay {
  const _StudyDay({required this.date, this.total = 0, this.correct = 0});
  factory _StudyDay.fromJson(Map<String, dynamic> json) => _$StudyDayFromJson(json);

@override final  String date;
@override@JsonKey() final  int total;
@override@JsonKey() final  int correct;

/// Create a copy of StudyDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyDayCopyWith<_StudyDay> get copyWith => __$StudyDayCopyWithImpl<_StudyDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudyDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyDay&&(identical(other.date, date) || other.date == date)&&(identical(other.total, total) || other.total == total)&&(identical(other.correct, correct) || other.correct == correct));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,total,correct);

@override
String toString() {
  return 'StudyDay(date: $date, total: $total, correct: $correct)';
}


}

/// @nodoc
abstract mixin class _$StudyDayCopyWith<$Res> implements $StudyDayCopyWith<$Res> {
  factory _$StudyDayCopyWith(_StudyDay value, $Res Function(_StudyDay) _then) = __$StudyDayCopyWithImpl;
@override @useResult
$Res call({
 String date, int total, int correct
});




}
/// @nodoc
class __$StudyDayCopyWithImpl<$Res>
    implements _$StudyDayCopyWith<$Res> {
  __$StudyDayCopyWithImpl(this._self, this._then);

  final _StudyDay _self;
  final $Res Function(_StudyDay) _then;

/// Create a copy of StudyDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? total = null,Object? correct = null,}) {
  return _then(_StudyDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,correct: null == correct ? _self.correct : correct // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StudyHistory {

 List<StudyDay> get days; int get totalReviews;
/// Create a copy of StudyHistory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudyHistoryCopyWith<StudyHistory> get copyWith => _$StudyHistoryCopyWithImpl<StudyHistory>(this as StudyHistory, _$identity);

  /// Serializes this StudyHistory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudyHistory&&const DeepCollectionEquality().equals(other.days, days)&&(identical(other.totalReviews, totalReviews) || other.totalReviews == totalReviews));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(days),totalReviews);

@override
String toString() {
  return 'StudyHistory(days: $days, totalReviews: $totalReviews)';
}


}

/// @nodoc
abstract mixin class $StudyHistoryCopyWith<$Res>  {
  factory $StudyHistoryCopyWith(StudyHistory value, $Res Function(StudyHistory) _then) = _$StudyHistoryCopyWithImpl;
@useResult
$Res call({
 List<StudyDay> days, int totalReviews
});




}
/// @nodoc
class _$StudyHistoryCopyWithImpl<$Res>
    implements $StudyHistoryCopyWith<$Res> {
  _$StudyHistoryCopyWithImpl(this._self, this._then);

  final StudyHistory _self;
  final $Res Function(StudyHistory) _then;

/// Create a copy of StudyHistory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? totalReviews = null,}) {
  return _then(_self.copyWith(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<StudyDay>,totalReviews: null == totalReviews ? _self.totalReviews : totalReviews // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StudyHistory].
extension StudyHistoryPatterns on StudyHistory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudyHistory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudyHistory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudyHistory value)  $default,){
final _that = this;
switch (_that) {
case _StudyHistory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudyHistory value)?  $default,){
final _that = this;
switch (_that) {
case _StudyHistory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<StudyDay> days,  int totalReviews)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudyHistory() when $default != null:
return $default(_that.days,_that.totalReviews);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<StudyDay> days,  int totalReviews)  $default,) {final _that = this;
switch (_that) {
case _StudyHistory():
return $default(_that.days,_that.totalReviews);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<StudyDay> days,  int totalReviews)?  $default,) {final _that = this;
switch (_that) {
case _StudyHistory() when $default != null:
return $default(_that.days,_that.totalReviews);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudyHistory implements StudyHistory {
  const _StudyHistory({final  List<StudyDay> days = const <StudyDay>[], this.totalReviews = 0}): _days = days;
  factory _StudyHistory.fromJson(Map<String, dynamic> json) => _$StudyHistoryFromJson(json);

 final  List<StudyDay> _days;
@override@JsonKey() List<StudyDay> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

@override@JsonKey() final  int totalReviews;

/// Create a copy of StudyHistory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudyHistoryCopyWith<_StudyHistory> get copyWith => __$StudyHistoryCopyWithImpl<_StudyHistory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudyHistoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudyHistory&&const DeepCollectionEquality().equals(other._days, _days)&&(identical(other.totalReviews, totalReviews) || other.totalReviews == totalReviews));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_days),totalReviews);

@override
String toString() {
  return 'StudyHistory(days: $days, totalReviews: $totalReviews)';
}


}

/// @nodoc
abstract mixin class _$StudyHistoryCopyWith<$Res> implements $StudyHistoryCopyWith<$Res> {
  factory _$StudyHistoryCopyWith(_StudyHistory value, $Res Function(_StudyHistory) _then) = __$StudyHistoryCopyWithImpl;
@override @useResult
$Res call({
 List<StudyDay> days, int totalReviews
});




}
/// @nodoc
class __$StudyHistoryCopyWithImpl<$Res>
    implements _$StudyHistoryCopyWith<$Res> {
  __$StudyHistoryCopyWithImpl(this._self, this._then);

  final _StudyHistory _self;
  final $Res Function(_StudyHistory) _then;

/// Create a copy of StudyHistory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? totalReviews = null,}) {
  return _then(_StudyHistory(
days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<StudyDay>,totalReviews: null == totalReviews ? _self.totalReviews : totalReviews // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
