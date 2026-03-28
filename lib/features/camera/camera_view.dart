import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_controller.dart';
import 'package:camera/camera.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraControllerManager _manager = CameraControllerManager();

  bool isLoading = true;
  String streamUrl = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// 🔥 Get device IP
  Future<String> getLocalIp() async {
    final interfaces = await NetworkInterface.list();

    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          return addr.address;
        }
      }
    }
    return "0.0.0.0";
  }

  Future<void> _init() async {
    await _manager.init();

    final ip = await getLocalIp();

    setState(() {
      streamUrl = "http://$ip:8080";
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  void _toggleStreaming() async {
    if (!_manager.isStreaming) {
      await _manager.startStreaming();
    } else {
      await _manager.stopStreaming();
    }
    setState(() {});
  }

  void _copyUrl() {
    Clipboard.setData(ClipboardData(text: streamUrl));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Stream URL copied 🚀")));
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = isLoading ? null : _manager.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("CamForge"),
        centerTitle: true,
        backgroundColor: Colors.black,
      ),
      body: isLoading || controller == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// 🎥 CAMERA PREVIEW
                Expanded(
                  child: Stack(
                    children: [
                      CameraPreview(controller),

                      /// 🔴 LIVE BADGE
                      if (_manager.isStreaming)
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              "LIVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                /// 🔗 STREAM URL BOX
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[900],
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          streamUrl.isEmpty ? "Fetching IP..." : streamUrl,
                          style: const TextStyle(color: Colors.white70),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _copyUrl,
                        icon: const Icon(Icons.copy, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                /// 🎮 START / STOP BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _manager.isStreaming
                            ? Colors.red
                            : Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _toggleStreaming,
                      child: Text(
                        _manager.isStreaming
                            ? "🛑 Stop Streaming"
                            : "🚀 Start Streaming",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
