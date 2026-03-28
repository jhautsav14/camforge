import 'dart:async';
import 'package:camera/camera.dart';

class CameraService {
  late CameraController controller;

  bool _isStreamingImages = false;
  StreamController<CameraImage>? _controllerStream;

  Future<void> init() async {
    final cameras = await availableCameras();
    final camera = cameras.first;

    controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();
    print("[CameraService] Camera initialized");
  }

  Stream<CameraImage> startImageStream() {
    if (_isStreamingImages) {
      print("[CameraService] ⚠️ Stream already running");
      return _controllerStream!.stream;
    }

    _controllerStream = StreamController<CameraImage>.broadcast();

    controller.startImageStream((CameraImage image) {
      _controllerStream?.add(image);
    });

    _isStreamingImages = true;
    print("[CameraService] ✅ Image stream started");

    return _controllerStream!.stream;
  }

  Future<void> stopStream() async {
    if (!_isStreamingImages) return;

    await controller.stopImageStream();
    await _controllerStream?.close();

    _isStreamingImages = false;
    print("[CameraService] 🛑 Image stream stopped");
  }

  void dispose() {
    controller.dispose();
    print("[CameraService] disposed");
  }
}
