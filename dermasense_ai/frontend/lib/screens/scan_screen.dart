import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  XFile? _selectedImage;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  final ImagePicker _picker = ImagePicker();

  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    // Simulate a sweeping scan line
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _scanController,
      curve: Curves.easeInOut,
    ));

    _initializeLiveCamera();
  }

  Future<void> _initializeLiveCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty && mounted) {
        final backCamera = _cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.max,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Camera initialization warning: $e");
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error picking image from gallery: $e");
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      debugPrint("Error capturing image from camera: $e");
    }
  }

  Future<void> _captureLiveImage() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile file = await _cameraController!.takePicture();
        setState(() {
          _selectedImage = file;
        });
      } catch (e) {
        debugPrint("Error taking picture with live camera: $e. Falling back to camera picker.");
        _captureImage();
      }
    } else {
      _captureImage();
    }
  }

  void _analyzeImage() {
    if (_selectedImage != null) {
      Navigator.pushNamed(context, '/processing', arguments: _selectedImage!.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1A211D), // Dark mode for scanner
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Skin Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Clean Dark Camera Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [Color(0xFF2C3931), Color(0xFF1A211D)],
                  center: Alignment.center,
                  radius: 1.0,
                ),
              ),
              child: _selectedImage == null && !_isCameraInitialized
                  ? Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 200,
                        color: Colors.white.withOpacity(0.03),
                      ),
                    )
                  : null,
            ),
          ),
          
          // Scanning Viewfinder Overlay
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Position the affected area within the frame',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        child: Stack(
                          children: [
                            // 1. Live Camera Preview (when no image is captured yet)
                            if (_selectedImage == null && _isCameraInitialized && _cameraController != null)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _cameraController!.value.previewSize!.height,
                                        height: _cameraController!.value.previewSize!.width,
                                        child: CameraPreview(_cameraController!),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // 2. Real Captured Image Preview inside the viewfinder (Web Safe)
                            if (_selectedImage != null)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: kIsWeb
                                        ? Image.network(
                                            _selectedImage!.path,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.file(
                                            File(_selectedImage!.path),
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                ),
                              ),
                            
                            // Viewfinder Frame brackets
                            _buildFrameCorners(primaryColor),
                            
                            // Scanning Line Animation constrained inside the actual viewport
                            if (_selectedImage != null)
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return AnimatedBuilder(
                                    animation: _scanAnimation,
                                    builder: (context, child) {
                                      return Positioned(
                                        top: _scanAnimation.value * (constraints.maxHeight - 4),
                                        left: 4,
                                        right: 4,
                                        child: Container(
                                          height: 3,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            boxShadow: [
                                              BoxShadow(
                                                color: primaryColor.withOpacity(0.8),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                
                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF1A211D).withOpacity(0.0),
                        const Color(0xFF1A211D),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: _selectedImage == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.photo_library_rounded, 'Gallery', Colors.white24, _pickImage),
                            GestureDetector(
                              onTap: _captureLiveImage,
                              child: Container(
                                height: 80,
                                width: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primaryColor, width: 4),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 30),
                                ),
                              ),
                            ),
                            _buildActionButton(Icons.info_outline_rounded, 'Guide', Colors.white24, () {
                              Navigator.pushNamed(context, '/guidance');
                            }),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _analyzeImage,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [primaryColor, Color(0xFF10B981)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Analyze Skin with AI ✨',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Choose Another',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color bgColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildFrameCorners(Color color) {
    return Stack(
      children: [
        // Top Left
        Positioned(
          top: 0, left: 0,
          child: _buildCorner(color, false, false),
        ),
        // Top Right
        Positioned(
          top: 0, right: 0,
          child: _buildCorner(color, true, false),
        ),
        // Bottom Left
        Positioned(
          bottom: 0, left: 0,
          child: _buildCorner(color, false, true),
        ),
        // Bottom Right
        Positioned(
          bottom: 0, right: 0,
          child: _buildCorner(color, true, true),
        ),
      ],
    );
  }

  Widget _buildCorner(Color color, bool isRight, bool isBottom) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isBottom ? BorderSide.none : BorderSide(color: color, width: 4),
          bottom: isBottom ? BorderSide(color: color, width: 4) : BorderSide.none,
          left: isRight ? BorderSide.none : BorderSide(color: color, width: 4),
          right: isRight ? BorderSide(color: color, width: 4) : BorderSide.none,
        ),
      ),
    );
  }
}
