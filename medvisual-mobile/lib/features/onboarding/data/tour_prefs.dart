import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding turunun gosterilip gosterilmedigini saklar.
class TourPrefs {
  static const _key = 'tour_done';

  static Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
