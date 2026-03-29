import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'camera_controller.dart';
import 'package:camera/camera.dart';

enum ConnectionMode { wifi, usb }

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final CameraControllerManager _manager = CameraControllerManager();

  bool isLoading = true;
  ConnectionMode _currentMode = ConnectionMode.wifi;

  String wifiIp = "";
  String usbTetherIp = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// 🔥 Get device IPs for both Wi-Fi and USB Tethering
  Future<void> _fetchIps() async {
    final interfaces = await NetworkInterface.list();

    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
          // Identify network type by interface name
          if (interface.name.contains('wlan') ||
              interface.name.contains('ap')) {
            wifiIp = addr.address;
          } else if (interface.name.contains('rndis') ||
              interface.name.contains('usb')) {
            usbTetherIp = addr.address;
          } else {
            // Fallback if name is non-standard
            if (wifiIp.isEmpty) wifiIp = addr.address;
          }
        }
      }
    }

    // Default fallback if nothing is found
    if (wifiIp.isEmpty) wifiIp = "0.0.0.0";
  }

  Future<void> _init() async {
    await _manager.init();
    await _fetchIps();

    setState(() {
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

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Stream URL copied 🚀")));
  }

  /// 🛠️ Builds the URL and Instruction box based on the selected mode
  Widget _buildConnectionInfoBox() {
    String url = "";
    String instructions = "";

    if (_currentMode == ConnectionMode.wifi) {
      url = "http://$wifiIp:8080";
      instructions = "Ensure devices are on the same Wi-Fi network.";
    } else {
      if (usbTetherIp.isNotEmpty) {
        url = "http://$usbTetherIp:8080";
        instructions = "USB Tethering active. Use this direct IP:";
      } else {
        url = "http://localhost:8080";
        instructions =
            "1. Connect USB\n2. Run in PC Terminal: adb forward tcp:8080 tcp:8080";
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instructions,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    url,
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: () => _copyUrl(url),
                icon: const Icon(Icons.copy, color: Colors.white),
                tooltip: "Copy URL",
              ),
            ],
          ),
        ],
      ),
    );
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

                const SizedBox(height: 15),

                /// 🔄 WI-FI / USB TOGGLE
                /// 🔄 WI-FI / USB TOGGLE & HELP BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text("Wi-Fi"),
                      selected: _currentMode == ConnectionMode.wifi,
                      onSelected: (val) {
                        if (val)
                          setState(() => _currentMode = ConnectionMode.wifi);
                      },
                      selectedColor: Colors.blueAccent.withOpacity(0.3),
                      checkmarkColor: Colors.blueAccent,
                    ),
                    const SizedBox(width: 15),
                    ChoiceChip(
                      label: const Text("USB"),
                      selected: _currentMode == ConnectionMode.usb,
                      onSelected: (val) {
                        if (val)
                          setState(() => _currentMode = ConnectionMode.usb);
                      },
                      selectedColor: Colors.blueAccent.withOpacity(0.3),
                      checkmarkColor: Colors.blueAccent,
                    ),
                    const SizedBox(width: 10),

                    /// 💡 NEW HELP BUTTON HERE
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: Colors.white54,
                      ),
                      tooltip: "How to connect",
                      onPressed: _showHelpDialog,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                /// 🔗 CONNECTION INFO BOX
                _buildConnectionInfoBox(),

                const SizedBox(height: 15),

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
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30), // Bottom padding
              ],
            ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blueAccent),
              SizedBox(width: 10),
              Text("How to Connect", style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                /// WI-FI INSTRUCTIONS
                Text(
                  "📶 Wi-Fi Mode",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "• Connect your phone and PC to the exact same Wi-Fi network.\n"
                  "• Type the provided Stream URL into your web browser or a media player like VLC.",
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),

                Divider(color: Colors.white24, height: 30, thickness: 1),

                /// USB INSTRUCTIONS
                Text(
                  "🔌 USB Mode",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Option A: USB Tethering (Easiest)\n"
                  "Turn on 'USB Tethering' in your phone's hotspot settings. The app will detect the new IP automatically.\n\n"
                  "Option B: ADB Port Forwarding (For PC)\n"
                  "1. Connect phone via USB (enable USB Debugging).\n"
                  "2. Open your PC terminal/command prompt.\n"
                  "3. Run: adb forward tcp:8080 tcp:8080\n"
                  "4. Open http://localhost:8080 in your browser.",
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Got it!",
                style: TextStyle(color: Colors.blueAccent, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
}
