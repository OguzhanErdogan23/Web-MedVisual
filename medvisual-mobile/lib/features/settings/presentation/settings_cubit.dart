import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../core/api_client.dart';
import '../../../core/safe_emit.dart';
import '../../../core/widgets.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

part 'settings_cubit.freezed.dart';

@freezed
abstract class SettingsState with _$SettingsState {
  const factory SettingsState({
    @Default(ViewStatus.initial) ViewStatus status,
    Profile? profile,
    @Default(false) bool saving,
    String? error,
    String? notice,
  }) = _SettingsState;
}

/// Ayarlar ekrani: profil yukle/kaydet + sifre degistir.
class SettingsCubit extends Cubit<SettingsState> with SafeEmit {
  SettingsCubit(this._repo, this._client) : super(const SettingsState());

  final ProfileRepository _repo;
  final SupabaseClient _client;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      final profile = await _repo.get();
      safeEmit(state.copyWith(status: ViewStatus.success, profile: profile));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> saveDisplayName(String displayName) async {
    emit(state.copyWith(saving: true));
    try {
      final profile = await _repo.updateDisplayName(displayName);
      safeEmit(state.copyWith(saving: false, profile: profile));
      _notify('Profil güncellendi.');
    } on ApiException catch (e) {
      safeEmit(state.copyWith(saving: false));
      _notify(e.message);
    }
  }

  Future<void> changePassword(String newPassword) async {
    emit(state.copyWith(saving: true));
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      safeEmit(state.copyWith(saving: false));
      _notify('Şifre değiştirildi.');
    } on AuthException catch (e) {
      safeEmit(state.copyWith(saving: false));
      _notify('Şifre değiştirilemedi: ${e.message}');
    } catch (_) {
      safeEmit(state.copyWith(saving: false));
      _notify('Şifre değiştirilemedi. Lütfen tekrar deneyin.');
    }
  }

  void _notify(String message) {
    safeEmit(state.copyWith(notice: message));
    safeEmit(state.copyWith(notice: null));
  }
}
