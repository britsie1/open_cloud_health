import 'package:flutter/services.dart';

class SecurityUtils {
  static const MethodChannel _channel = MethodChannel('com.opencloudhealth.app/security');

  /// Returns true if the device has a secure lock screen enabled (PIN, passcode, pattern, or biometrics).
  static Future<bool> isDeviceSecure() async {
    try {
      final bool? isSecure = await _channel.invokeMethod<bool>('isDeviceSecure');
      return isSecure ?? false;
    } catch (e) {
      // Fallback in case of failure or unsupported platform (e.g. desktop/web during tests)
      return false;
    }
  }
}
