import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_config.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isProcessing = false;
  int _currentStage = 0;
  Timer? _stageTimer;

  final List<String> _stages = [
    "Verifying Server Connection...",
    "Pre-processing Image...",
    "Running YOLOv8 Detection...",
    "Calculating Severity Index...",
    "Saving Results to Cloud..."
  ];

  @override
  void initState() {
    super.initState();
    _startStageSimulation();
  }

  void _startStageSimulation() {
    _stageTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_currentStage < 3) {
        setState(() {
          _currentStage++;
        });
      } else {
        _stageTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isProcessing) {
      _isProcessing = true;
      final imagePath = ModalRoute.of(context)?.settings.arguments as String?;
      if (imagePath != null) {
        _uploadAndAnalyzeImage(imagePath);
      } else {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _uploadAndAnalyzeImage(String imagePath) async {
    try {
      String apiUrl = AppConfig.apiUrl;

      // 1. Verify backend connectivity before upload
      setState(() {
        _currentStage = 0; // Verifying Server Connection
      });
      try {
        final rootUrl = AppConfig.baseUrl;
        final healthCheck = await http.get(Uri.parse(rootUrl)).timeout(const Duration(seconds: 5));
        if (healthCheck.statusCode != 200 && healthCheck.statusCode != 404) {
          throw Exception("API Health Check Failed");
        }
      } catch (e) {
        _showError('Server not reachable. Please check backend connection.');
        return;
      }

      setState(() {
        _currentStage = 1; // Pre-processing
      });

      // 2. Load bytes in a web-safe manner
      Uint8List bytes;
      String filename = 'image.jpg';

      if (kIsWeb) {
        final res = await http.get(Uri.parse(imagePath));
        bytes = res.bodyBytes;
      } else {
        bytes = await File(imagePath).readAsBytes();
        filename = imagePath.split('/').last;
      }

      setState(() {
        _currentStage = 2; // YOLO Detection
      });

      // 3. Post image bytes
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: filename,
      ));

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (!mounted) return;

        // Force transition to cloud stage
        _stageTimer?.cancel();
        setState(() {
          _currentStage = 4; // Saving results to cloud
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('scans')
                .add({
              'modelVersion': 'YOLOv8m',
              'acneCount': jsonResponse['acneCount'] ?? 0,
              'pimpleCount': jsonResponse['acneCount'] ?? 0,
              'severityScore': jsonResponse['severityScore'] ?? 1,
              'severityLabel': jsonResponse['severityLabel'] ?? 'Clear',
              'severity': jsonResponse['severityLabel'] ?? 'Clear',
              'confidence': double.tryParse((jsonResponse['confidence'] ?? 0.0).toString()) ?? 0.0,
              'guidanceAdvice': jsonResponse['recommendations']?['advice'] ?? '',
              'safetyWarnings': jsonResponse['recommendations']?['safety_warnings'] ?? [],
              'imageUrl': imagePath,
              'createdAt': FieldValue.serverTimestamp(),
              'timestamp': FieldValue.serverTimestamp(),
              'scanDate': FieldValue.serverTimestamp(),
            });
          } catch (firebaseErr) {
            debugPrint("Firebase Sync Warning: $firebaseErr");
          }
        }

        await Future.delayed(const Duration(milliseconds: 600));

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/results', arguments: {
          'data': jsonResponse,
          'imagePath': imagePath,
        });
      } else {
        _showError('Server Error: ${response.statusCode}');
      }
    } on TimeoutException {
      _showError('Server timeout. Please check backend connection.');
    } catch (e) {
      _showError('Connection Error: Make sure backend is running.');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
    ));
    Navigator.pop(context); // return to scan screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A211D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF20D284)),
            const SizedBox(height: 40),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                _stages[_currentStage],
                key: ValueKey<int>(_currentStage),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stages.length, (index) {
                final isActive = index <= _currentStage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF20D284) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
