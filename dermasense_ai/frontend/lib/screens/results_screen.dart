import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Catch arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final response = args?['data'] as Map<String, dynamic>?;
    final imagePath = args?['imagePath'] as String?;
    
    // Parse the JSON data securely matching the new one-class acne model structure
    final int severityScore = response?['severityScore'] ?? 1;
    final String severityLabel = response?['severityLabel'] ?? 'Clear';
    final int acneCount = response?['acneCount'] ?? 0;
    final double confidenceVal = double.tryParse((response?['confidence'] ?? 0.0).toString()) ?? 0.0;
    final recommendations = response?['recommendations'] as Map<dynamic, dynamic>? ?? {};
    
    final guidanceData = {
      'advice': recommendations['advice'] ?? 'No advice details provided.',
      'safety_warnings': recommendations['safety_warnings'] ?? [],
    };

    // Dynamic UI logic based on severity
    Color severityColor;
    if (severityLabel == 'Clear' || severityLabel == 'Mild') {
      severityColor = const Color(0xFF20D284); // Green
    } else if (severityLabel == 'Moderate') {
      severityColor = const Color(0xFFFFB020); // Orange
    } else {
      severityColor = const Color(0xFFFF4A8D); // Red
    }

    const textColor = Color(0xFF1A211D);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFA),
      appBar: AppBar(
        title: const Text('Scan Results', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: textColor),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              children: [
                // Image Preview
                if (imagePath != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                      image: DecorationImage(
                        image: (imagePath.startsWith('http://') || imagePath.startsWith('https://') || imagePath.startsWith('blob:') || kIsWeb)
                            ? NetworkImage(imagePath) as ImageProvider
                            : FileImage(File(imagePath)),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.center_focus_strong, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '$acneCount Estimated Pimples',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main Score Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Severity Score: $severityScore/10',
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Severity Category: $severityLabel',
                        style: const TextStyle(
                          color: textColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Detection Confidence: ${(confidenceVal * 100).toInt()}%',
                        style: TextStyle(
                          color: textColor.withOpacity(0.6),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (severityScore > 3)
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.healing_rounded, color: Color(0xFFD32F2F), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'It is recommended to consult a dermatologist for professional guidance.',
                            style: TextStyle(
                              color: Color(0xFFC62828),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Detected Pimples Stat Card (Full width, no scars card)
                _buildStatCard('Estimated Pimples', acneCount.toString(), const Color(0xFFFFB020)),
                
                const SizedBox(height: 30),
                
                // Actions
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/guidance', arguments: guidanceData);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF20D284),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF20D284).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'View AI Guidance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/book-consultation',
                      arguments: {
                        'severityScore': severityScore,
                        'severityLabel': severityLabel,
                        'acneCount': acneCount,
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFFFFB020), width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.video_call_rounded, color: Color(0xFFFF8F00)),
                        SizedBox(width: 8),
                        Text(
                          'Book Telederma Consultation',
                          style: TextStyle(
                            color: Color(0xFFFF8F00),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final shareText = "My DermaSense AI Scan Results:\n"
                        "Severity: $severityLabel\n"
                        "Estimated Pimples: $acneCount\n"
                        "Detection Confidence: ${(confidenceVal * 100).toInt()}%\n"
                        "Generated using DermaSense AI.";
                    Share.share(shareText);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    margin: const EdgeInsets.only(top: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                      border: Border.all(color: const Color(0xFF20D284), width: 2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_rounded, color: Color(0xFF20D284)),
                        SizedBox(width: 8),
                        Text(
                          'Share Results',
                          style: TextStyle(
                            color: Color(0xFF20D284),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Return to Dashboard',
                      style: TextStyle(
                        color: Color(0xFF8B9A92),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF8B9A92),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
