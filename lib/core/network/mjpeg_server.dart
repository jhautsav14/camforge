import 'dart:async';
import 'dart:io';

class MjpegServer {
  HttpServer? _server;

  Future<void> start(Stream<List<int>> jpegStream) async {
    final interfaces = await NetworkInterface.list();

    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          print("🌐 STREAM URL: http://${addr.address}:8080");
        }
      }
    }

    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);

    await for (HttpRequest request in _server!) {
      request.response.headers.set(
        HttpHeaders.contentTypeHeader,
        "multipart/x-mixed-replace; boundary=frame",
      );

      await for (var frame in jpegStream) {
        request.response.write("--frame\r\n");
        request.response.write("Content-Type: image/jpeg\r\n\r\n");
        request.response.add(frame);
        request.response.write("\r\n");
        await request.response.flush();
      }
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    print("🛑 Server stopped");
  }
}
