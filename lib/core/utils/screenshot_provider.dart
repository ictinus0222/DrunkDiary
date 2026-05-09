import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenshot/screenshot.dart';

final screenshotControllerProvider = Provider<ScreenshotController>((ref) {
  return ScreenshotController();
});

class ScreenshotInProgress extends Notifier<bool> {
  @override
  bool build() => false;
  
  void set(bool value) => state = value;
}

final feedbackScreenshotInProgressProvider = NotifierProvider<ScreenshotInProgress, bool>(ScreenshotInProgress.new);
