import 'package:shared_preferences/shared_preferences.dart';
import 'package:keychain_shop/constants/app_constants.dart';

/// Local preferences helper (onboarding flag, FCM token cache).
class PrefsHelper {
  PrefsHelper._();

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
  }

  static Future<void> setOnboardingComplete({bool value = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, value);
  }
}
