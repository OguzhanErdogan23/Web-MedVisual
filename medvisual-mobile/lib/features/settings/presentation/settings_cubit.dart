import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../core/api_client.dart';
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
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repo, this._client) : super(const SettingsState());

  final ProfileRepository _repo;
  final SupabaseClient _client;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      final profile = await _repo.get();
      emit(state.copyWith(status: ViewStatus.success, profile: profile));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> saveDisplayName(String displayName) async {
    emit(state.copyWith(saving: true));
    try {
      final profile = await _repo.updateDisplayName(displayName);
      emit(state.copyWith(saving: false, profile: profile));
      _notify('Profil guncellendi.');
    } on ApiException catch (e) {
      emit(state.copyWith(saving: false));
      _notify(e.message);
    }
  }

  Future<void> changePassword(String newPassword) async {
    emit(state.copyWith(saving: true));
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      emit(state.copyWith(saving: false));
      _notify('Sifre degistirildi.');
    } on AuthException catch (e) {
      emit(state.copyWith(saving: false));
      _notify('Sifre degistirilemedi: ${e.message}');
    } catch (_) {
      emit(state.copyWith(saving: false));
      _notify('Sifre degistirilemedi. Lutfen tekrar deneyin.');
    }
  }

  void _notify(String message) {
    emit(state.copyWith(notice: message));
    emit(state.copyWith(notice: null));
  }
}
