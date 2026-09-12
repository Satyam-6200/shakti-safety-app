import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class SMSService {
  static const platform = MethodChannel('com.example.shakti/sms');

  Future<bool> sendAutomaticSMS({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      var status = await Permission.sms.status;
      if (!status.isGranted) {
        status = await Permission.sms.request();
        if (!status.isGranted) {
          debugPrint('SMS permission denied');
          return false;
        }
      }
      await platform.invokeMethod('sendSMS', {
        'phone': phoneNumber,
        'message': message,
      });
      debugPrint('✅ SMS sent to $phoneNumber');
      return true;
    } on PlatformException catch (e) {
      debugPrint('❌ SMS failed: ${e.message}');
      return false;
    }
  }

  Future<void> sendBulkSMS({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    for (String phone in phoneNumbers) {
      await sendAutomaticSMS(phoneNumber: phone, message: message);
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
