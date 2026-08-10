import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/processing_screen.dart';
import 'screens/results_screen.dart';
import 'screens/guidance_screen.dart';
import 'screens/community_screen.dart';
import 'screens/funfact_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/scan_history_screen.dart';
import 'screens/about_ai_screen.dart';
import 'screens/help_center_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/book_consultation_screen.dart';

import 'screens/create_post_screen.dart';
import 'services/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load custom backend server configuration from SharedPreferences
  await AppConfig.loadPersistedIP();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase INIT Warning: $e");
  }

  runApp(const DermaSenseApp());
}

class DermaSenseApp extends StatelessWidget {
  const DermaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Derma Sense AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/scan': (context) => const ScanScreen(),
        '/processing': (context) => const ProcessingScreen(),
        '/results': (context) => const ResultsScreen(),
        '/guidance': (context) => const GuidanceScreen(),
        '/community': (context) => const CommunityScreen(),
        '/create-post': (context) => const CreatePostScreen(),
        '/funfact': (context) => const FunFactScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/history': (context) => const ScanHistoryScreen(),
        '/about-ai': (context) => const AboutAiScreen(),
        '/help-center': (context) => const HelpCenterScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/book-consultation': (context) => const BookConsultationScreen(),
      },
    );
  }
}
