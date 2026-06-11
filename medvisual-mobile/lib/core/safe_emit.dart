import 'package:flutter_bloc/flutter_bloc.dart';

/// Kapanmis bir Cubit'e emit StateError firlatir (orn. uzun suren bir istek
/// devam ederken kullanici sheet'i/ekrani kapatirsa). Async metodlarda await
/// sonrasi guvenli emit icin bu mixin kullanilir.
mixin SafeEmit<S> on Cubit<S> {
  void safeEmit(S state) {
    if (!isClosed) emit(state);
  }
}
