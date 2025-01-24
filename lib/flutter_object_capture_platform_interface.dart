import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_object_capture_method_channel.dart';

abstract class FlutterObjectCapturePlatform extends PlatformInterface {
  /// Constructs a FlutterObjectCapturePlatform.
  FlutterObjectCapturePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterObjectCapturePlatform _instance = MethodChannelFlutterObjectCapture();

  /// The default instance of [FlutterObjectCapturePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterObjectCapture].
  static FlutterObjectCapturePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterObjectCapturePlatform] when
  /// they register themselves.
  static set instance(FlutterObjectCapturePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
