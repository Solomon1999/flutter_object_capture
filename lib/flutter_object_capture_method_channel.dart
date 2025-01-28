import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_object_capture_platform_interface.dart';

/// An implementation of [FlutterObjectCapturePlatform] that uses method channels.
class MethodChannelFlutterObjectCapture extends FlutterObjectCapturePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_object_capture');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
