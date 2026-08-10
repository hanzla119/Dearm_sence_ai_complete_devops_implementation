import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/derma_logo.dart';
import '../services/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isDialogOpen = false;
  int _logoTapCount = 0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..addListener(() {
        setState(() {});
      });

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();

    // Secure redirection timer with offline fail-safe
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDialogOpen) {
        _navigateToNextScreen();
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint("Firebase Auth startup warning: $e. Falling back to offline login mode.");
      // Bypasses Firebase Core "no-app" crash and routes to login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _handleLogoInteraction() {
    setState(() {
      _logoTapCount++;
    });
    if (_logoTapCount >= 5) {
      _logoTapCount = 0;
      _showHiddenDeveloperDialog();
    }
  }

  void _showHiddenDeveloperDialog() {
    setState(() {
      _isDialogOpen = true;
    });
    final controller = TextEditingController(text: AppConfig.apiIP);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.developer_mode_rounded, color: Color(0xFF20D284)),
              SizedBox(width: 12),
              Text('Developer Setup', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Flask server IP or ngrok tunnel URL:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'e.g. 192.168.1.5 or https://xxxx.ngrok-free.app',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _isDialogOpen = false;
                });
                Navigator.pop(context);
                _navigateToNextScreen();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20D284),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final newIP = controller.text.trim();
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                if (newIP.isNotEmpty) {
                  await AppConfig.saveIP(newIP);
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('API URL set to: ${AppConfig.apiUrl}')),
                  );
                }
                setState(() {
                  _isDialogOpen = false;
                });
                navigator.pop();
                _navigateToNextScreen();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    var primaryColor = const Color(0xFF20D284);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE5F7ED), 
              Color(0xFFF2FBF6), 
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            
            // Refined logo spacing
            GestureDetector(
              onTap: _handleLogoInteraction,
              onLongPress: _showHiddenDeveloperDialog,
              child: const Center(
                child: DermaLogo(size: 160),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title
            GestureDetector(
              onTap: _handleLogoInteraction,
              onLongPress: _showHiddenDeveloperDialog,
              child: const Text(
                'Derma Sense AI',
                style: TextStyle(
                  color: Color(0xFF1A211D),
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            const Text(
              'Your skin, your journey',
              style: TextStyle(
                color: Color(0xFF6B7A72),
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(flex: 2),
            
            // Loading Section
            Text(
              'SETTING UP YOUR ROUTINE...',
              style: TextStyle(
                color: const Color(0xFF6B7A72).withOpacity(0.8),
                fontSize: 11,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Progress Bar
            Container(
              width: size.width * 0.7,
              height: 6,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: (size.width * 0.7) * _animation.value,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
