import 'package:flutter/material.dart';
import 'features/camera/camera_view.dart';

class CamForgeApp extends StatelessWidget {
  const CamForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamForge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CameraPage(),
    );
  }
}
