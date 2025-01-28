import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef StringResultHandler = void Function(String? text);
typedef ObjectCapturePluginCreatedCallback = void Function(
    ObjectCaptureController controller);

class ObjectCaptureView extends StatefulWidget {
  final bool debug;
  final ObjectCapturePluginCreatedCallback onInitialiseObjectCapture;
  const ObjectCaptureView({
    super.key,
    required this.onInitialiseObjectCapture,
    this.debug = false,
  });

  @override
  State<ObjectCaptureView> createState() => _ObjectCaptureViewState();
}

class _ObjectCaptureViewState extends State<ObjectCaptureView> {
  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return Text('$defaultTargetPlatform is not supported by this plugin');
    }
    return UiKitView(
      viewType: 'flutter_object_capture',
      // creationParams: ,
      onPlatformViewCreated: onPlatformViewCreated,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }

  Future<void> onPlatformViewCreated(int id) async {
    widget.onInitialiseObjectCapture(
      ObjectCaptureController._init(
        id,
        widget.debug,
      ),
    );
  }
}

class ObjectCaptureController {
  late MethodChannel _channel;
  final bool debug;

  /// This is called when a session fails.
  /// On failure the session will be paused.
  StringResultHandler? onError;

  // Handle when result object path
  StringResultHandler? onCompleted;

  ObjectCaptureController._init(
    int id,
    this.debug,

    // ObjectCaptureConfiguration configuration,
  ) {
    _channel = MethodChannel('flutter_object_capture_$id');
    _channel.setMethodCallHandler(_platformCallHandler);
    _channel.invokeMethod<void>('startSession');
  }

  void dispose() {
    // _channel.invokeMethod<void>('dispose');
  }

  Future<void> _platformCallHandler(MethodCall call) {
    if (debug) {
      debugPrint('_platformCallHandler call ${call.method} ${call.arguments}');
    }
    try {
      switch (call.method) {
        case 'onError':
          if (onError != null) {
            onError!(call.arguments);
            debugPrint(call.arguments);
          }
          break;
        case 'onCompleted':
          if (onCompleted != null) {
            onCompleted!(call.arguments);
            debugPrint(call.arguments);
          }
          break;
      }
    } catch (error) {
      debugPrint(error.toString());
    }
    return Future.value();
  }
}
