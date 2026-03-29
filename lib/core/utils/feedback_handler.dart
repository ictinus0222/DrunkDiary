import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Utility class to handle feedback submission via email.
class FeedbackHandler {
  static Future<void> onFeedbackSubmitted(UserFeedback feedback) async {
    try {
      // 1. Save the screenshot to a temporary file
      final screenshotPath = await _saveScreenshot(feedback.screenshot);

      // 2. Get app and device information
      final packageInfo = await PackageInfo.fromPlatform();
      final String platformName = kIsWeb ? 'Web' : Platform.operatingSystem;

      // 3. Construct the email body
      final StringBuffer bodyBuffer = StringBuffer();
      bodyBuffer.writeln('User Feedback:');
      bodyBuffer.writeln(feedback.text);
      bodyBuffer.writeln();
      bodyBuffer.writeln('-----------------------------------------');
      bodyBuffer.writeln('System Information:');
      bodyBuffer.writeln('App Name: ${packageInfo.appName}');
      bodyBuffer.writeln('App Version: ${packageInfo.version}+${packageInfo.buildNumber}');
      bodyBuffer.writeln('Platform: $platformName');
      bodyBuffer.writeln('Timestamp: ${DateTime.now().toLocal()}');
      bodyBuffer.writeln('-----------------------------------------');

      // 4. Create the email
      final Email email = Email(
        body: bodyBuffer.toString(),
        subject: 'DrunkDiary App Feedback',
        recipients: ['akhil@drunkdiary.com'],
        attachmentPaths: [screenshotPath],
        isHTML: false,
      );

      // 5. Send the email
      await FlutterEmailSender.send(email);
    } catch (e) {
      debugPrint('Error sending feedback email: $e');
      rethrow;
    }
  }

  static Future<String> _saveScreenshot(Uint8List screenshot) async {
    final Directory tempDir = await getTemporaryDirectory();
    final String path = '${tempDir.path}/feedback_screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
    final File file = File(path);
    await file.writeAsBytes(screenshot);
    return path;
  }
}
