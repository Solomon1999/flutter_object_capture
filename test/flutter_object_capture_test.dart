import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture/flutter_object_capture_platform_interface.dart';
import 'package:flutter_object_capture/flutter_object_capture_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterObjectCapturePlatform
    with MockPlatformInterfaceMixin
    implements FlutterObjectCapturePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final FlutterObjectCapturePlatform initialPlatform = FlutterObjectCapturePlatform.instance;

  test('$MethodChannelFlutterObjectCapture is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterObjectCapture>());
  });

  test('getPlatformVersion', () async {
    FlutterObjectCapture flutterObjectCapturePlugin = FlutterObjectCapture();
    MockFlutterObjectCapturePlatform fakePlatform = MockFlutterObjectCapturePlatform();
    FlutterObjectCapturePlatform.instance = fakePlatform;

    expect(await flutterObjectCapturePlugin.getPlatformVersion(), '42');
  });
}
