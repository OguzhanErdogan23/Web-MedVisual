import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile.freezed.dart';
part 'profile.g.dart';

/// Kullanici profili (immutable — freezed).
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? displayName,
    String? email,
    DateTime? createdAt,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}
