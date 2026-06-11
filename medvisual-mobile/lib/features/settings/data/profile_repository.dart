import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/offline_cache.dart';
import '../domain/profile.dart';

/// Profil uclari (GET/PATCH /profile).
class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<Profile> get() async {
    final data = await cachedJson('profile', () => guardApi(() async {
          final res = await _dio.get<Map<String, dynamic>>('/profile');
          return res.data!;
        }));
    return Profile.fromJson(data);
  }

  Future<Profile> updateDisplayName(String displayName) => guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/profile',
          data: {'display_name': displayName},
        );
        return Profile.fromJson(res.data!);
      });
}
