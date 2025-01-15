
import 'flutter_object_capture_platform_interface.dart';

class FlutterObjectCapture {
  Future<String?> getPlatformVersion() {
    return FlutterObjectCapturePlatform.instance.getPlatformVersion();
  }
}
