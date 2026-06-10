import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:supabase_flutter/supabase_flutter.dart' as supa
    show AuthState;

part 'auth_cubit.freezed.dart';

/// Kimlik durumu (immutable — freezed).
@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    required bool authenticated,
    @Default(false) bool busy,
    String? error,
    String? info,
    String? email,
  }) = _AuthState;
}

/// Supabase Auth sarmalayicisi: giris/kayit/cikis + oturum dinleme.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._client)
      : super(AuthState(
          authenticated: _client.auth.currentSession != null,
          email: _client.auth.currentSession?.user.email,
        )) {
    _sub = _client.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      emit(state.copyWith(
        authenticated: session != null,
        email: session?.user.email,
      ));
    });
  }

  final SupabaseClient _client;
  late final StreamSubscription<supa.AuthState> _sub;

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(busy: true, error: null, info: null));
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      emit(state.copyWith(busy: false));
    } on AuthException catch (e) {
      emit(state.copyWith(busy: false, error: _trAuthError(e)));
    } catch (_) {
      emit(state.copyWith(
          busy: false, error: 'Giris yapilamadi. Baglantiyi kontrol edin.'));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(state.copyWith(busy: true, error: null, info: null));
    try {
      final res = await _client.auth.signUp(email: email, password: password);
      emit(state.copyWith(
        busy: false,
        info: res.session == null
            ? 'Kayit alindi. E-postanizdaki dogrulama baglantisini onaylayin.'
            : null,
      ));
    } on AuthException catch (e) {
      emit(state.copyWith(busy: false, error: _trAuthError(e)));
    } catch (_) {
      emit(state.copyWith(
          busy: false, error: 'Kayit yapilamadi. Baglantiyi kontrol edin.'));
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Oturum yerelde de kapanir; hata yutulur.
    }
  }

  String _trAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-posta veya sifre hatali.';
    }
    if (msg.contains('already registered')) {
      return 'Bu e-posta zaten kayitli.';
    }
    if (msg.contains('password should be at least')) {
      return 'Sifre en az 6 karakter olmali.';
    }
    if (msg.contains('email not confirmed')) {
      return 'E-posta henuz dogrulanmamis. Gelen kutunuzu kontrol edin.';
    }
    if (msg.contains('invalid email') || msg.contains('validate email')) {
      return 'Gecersiz e-posta adresi.';
    }
    return 'Islem basarisiz: ${e.message}';
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
