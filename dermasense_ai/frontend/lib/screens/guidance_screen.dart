import 'package:flutter/material.dart';

class GuidanceScreen extends StatelessWidget {
  const GuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Extract guidance arguments passed from results screen
    final args = ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;
    final String advice = args?['advice'] as String? ?? 'No advice details provided.';
    final List<dynamic> safetyWarnings = args?['safety_warnings'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Skincare Guidance'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1A211D),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (safetyWarnings.isNotEmpty) ...[
              const Text(
                'Safety Warnings:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A211D)),
              ),
              const SizedBox(height: 12),
              ...safetyWarnings.map((warning) {
                IconData icon = Icons.warning_amber_rounded;
                Color iconColor = Colors.orange;
                if (warning.toString().contains('Consult')) {
                  icon = Icons.health_and_safety_rounded;
                  iconColor = Colors.blue;
                } else if (warning.toString().contains('Avoid')) {
                  icon = Icons.block_flipped;
                  iconColor = Colors.red;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Icon(icon, color: iconColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 32),
            ],
            const Text('Advice:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  advice,
                  style: const TextStyle(fontSize: 16, height: 1.5, color: Color(0xFF1A211D)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20D284),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
