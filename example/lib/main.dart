import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_object_capture/flutter_object_capture.dart';
import 'package:flutter_object_capture/widgets/object_capture_view.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _flutterObjectCapturePlugin = FlutterObjectCapture();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _flutterObjectCapturePlugin.getPlatformVersion() ??
              'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Running on: $_platformVersion\n'),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text("Scan Object"),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ObjectCapturePage extends StatefulWidget {
  final Function(String) onObjectCaptured;
  const ObjectCapturePage({super.key, required this.onObjectCaptured});

  @override
  State<ObjectCapturePage> createState() => _ObjectCapturePageState();
}

class _ObjectCapturePageState extends State<ObjectCapturePage> {
  late ObjectCaptureController controller;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onObjectCaptureInitialised(
      ObjectCaptureController objectCaptureController) {
    controller = controller;

    controller.onCompleted = (path) {
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Failed to get generated model"),
            action: SnackBarAction(
              label: "Close",
              onPressed: () {
                Navigator.maybePop(context);
              },
            ),
          ),
        );
        return;
      }
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ModelViewer(
                backgroundColor: const Color.fromARGB(0xFF, 0xEE, 0xEE, 0xEE),
                src: path,
                iosSrc: path,
                alt: 'A 3D model of an astronaut',
                ar: true,
                autoRotate: true,
                disableZoom: true,
              ),
            ],
          );
        },
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Object Capture Demo"),
      ),
      body: SafeArea(
        child: ObjectCaptureView(
          onInitialiseObjectCapture: onObjectCaptureInitialised,
        ),
      ),
    );
  }
}
