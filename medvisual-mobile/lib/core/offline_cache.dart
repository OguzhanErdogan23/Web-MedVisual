import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Cevrimdisi destek: son basarili API yanitlarinin yerel kopyasi.
///
/// Repository'ler GET yanitlarini buraya yazar; sunucuya ulasilamadiginda
/// (baglanti hatasi — HTTP durum kodu olmayan ApiException) ayni anahtardaki
/// son kopya dondurulur. Boylece daha once indirilen desteler/kartlar/quizler
/// internet veya sunucu olmadan da goruntulenebilir.
const _cachePrefix = 'cache.';
const _outboxKey = 'outbox.reviews';

Future<void> cachePut(String key, Object value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('$_cachePrefix$key', jsonEncode(value));
}

Future<Object?> cacheGet(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('$_cachePrefix$key');
  if (raw == null) return null;
  try {
    return jsonDecode(raw);
  } catch (_) {
    return null;
  }
}

/// Once agi dener; basarili yaniti cache'e yazar. Baglanti hatasinda
/// (statusCode == null) cache'teki son kopyayi dondurur, o da yoksa hatayi
/// aynen firlatir. Sunucunun gercek HTTP hatalari (4xx/5xx) cache'e DUSMEZ.
Future<Map<String, dynamic>> cachedJson(
  String key,
  Future<Map<String, dynamic>> Function() fetch,
) async {
  try {
    final data = await fetch();
    unawaited(cachePut(key, data));
    return data;
  } on ApiException catch (e) {
    if (e.statusCode != null) rethrow;
    final cached = await cacheGet(key);
    if (cached is Map<String, dynamic>) return cached;
    rethrow;
  }
}

// ---------------------------------------------------------------------------
// Cevrimdisi cevap kuyrugu (outbox): sunucuya yazilamayan SM-2 notlari
// burada bekler ve baglanti gelince siralariyla gonderilir.
// ---------------------------------------------------------------------------
Future<void> outboxAppend(Map<String, dynamic> review) async {
  final prefs = await SharedPreferences.getInstance();
  final items = await outboxPending();
  items.add(review);
  await prefs.setString(_outboxKey, jsonEncode(items));
}

Future<List<Map<String, dynamic>>> outboxPending() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_outboxKey);
  if (raw == null) return <Map<String, dynamic>>[];
  try {
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>().toList();
  } catch (_) {
    return <Map<String, dynamic>>[];
  }
}

Future<void> outboxReplace(List<Map<String, dynamic>> items) async {
  final prefs = await SharedPreferences.getInstance();
  if (items.isEmpty) {
    await prefs.remove(_outboxKey);
  } else {
    await prefs.setString(_outboxKey, jsonEncode(items));
  }
}
