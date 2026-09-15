import 'package:flutter/material.dart';
import 'package:app/camera_finger_instruction.dart';

void main() {
  runApp(const VMedithonApp());
}

class VMedithonApp extends StatelessWidget {
  const VMedithonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Instruction',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          surface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const CameraInstructionScreen(),
    );
  }
}

class CameraInstructionScreen extends StatelessWidget {
  const CameraInstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Measurement Setup',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: const SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: CameraFingerInstruction(),
          ),
        ),
      ),
    );
  }
}
