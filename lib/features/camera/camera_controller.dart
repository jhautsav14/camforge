import 'dart:async';
import 'package:camera/camera.dart';
import '../../../core/network/mjpeg_server.dart';
import 'camera_service.dart';
import 'package:image/image.dart' as img;

class CameraControllerManager {
  final CameraService _cameraService = CameraService();
  final MjpegServer _server = MjpegServer();

  final StreamController<List<int>> _jpegStreamController =
      StreamController.broadcast();

  bool isStreaming = false;

  StreamSubscription? _cameraSubscription;

  Future<void> init() async {
    await _cameraService.init();
  }

  CameraController get controller => _cameraService.controller;

  Future<void> startStreaming() async {
    if (isStreaming) {
      print("[Manager] ⚠️ Already streaming, ignoring...");
      return;
    }

    print("[Manager] 🚀 Starting stream...");

    final stream = _cameraService.startImageStream();

    _cameraSubscription = stream.listen((CameraImage image) {
      final jpeg = _convertToJpeg(image);
      _jpegStreamController.add(jpeg);
    });

    isStreaming = true;
    await _server.stop();
    _server.start(_jpegStreamController.stream);
    print("[Manager] ✅ Streaming started");
  }

  Future<void> stopStreaming() async {
    if (!isStreaming) return;

    print("[Manager] 🛑 Stopping stream...");

    await _cameraSubscription?.cancel();
    await _cameraService.stopStream();

    // ✅ STOP SERVER
    await _server.stop();

    isStreaming = false;

    print("[Manager] ❌ Streaming stopped");
  }

  List<int> _convertToJpeg(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final img.Image imgBuffer = img.Image(width: width, height: height);

    final planeY = image.planes[0];
    final planeU = image.planes[1];
    final planeV = image.planes[2];

    final int yRowStride = planeY.bytesPerRow;
    final int uvRowStride = planeU.bytesPerRow;
    final int uvPixelStride = planeU.bytesPerPixel!;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;

        final int uvX = x ~/ 2;
        final int uvY = y ~/ 2;

        final int uvIndex = uvY * uvRowStride + uvX * uvPixelStride;

        final int yp = planeY.bytes[yIndex];
        final int up = planeU.bytes[uvIndex];
        final int vp = planeV.bytes[uvIndex];

        int r = (yp + 1.402 * (vp - 128)).round();
        int g = (yp - 0.344136 * (up - 128) - 0.714136 * (vp - 128)).round();
        int b = (yp + 1.772 * (up - 128)).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        imgBuffer.setPixelRgb(x, y, r, g, b);
      }
    }

    return img.encodeJpg(imgBuffer, quality: 70);
  }

  void dispose() {
    stopStreaming();
    _cameraService.dispose();
    _jpegStreamController.close();
    print("[Manager] disposed");
  }
}
