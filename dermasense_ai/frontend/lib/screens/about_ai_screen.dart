import 'package:flutter/material.dart';

class AboutAiScreen extends StatelessWidget {
  const AboutAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    const bgColor = Color(0xFFF9FCFA);
    const textColor = Color(0xFF1A211D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'About AI Model',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  size: 80,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'AI Model Parameters',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'One-Class Active Acne Classification System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Info cards
            _buildInfoCard('Project Name', 'Derma Sense AI', Icons.app_registration_rounded, primaryColor),
            const SizedBox(height: 16),
            _buildInfoCard('Model Architecture', 'YOLOv8m (Medium)', Icons.model_training_rounded, primaryColor),
            const SizedBox(height: 16),
            _buildInfoCard('Detection Framework', 'Ultralytics YOLOv8', Icons.settings_system_daydream_rounded, primaryColor),
            const SizedBox(height: 16),
            _buildInfoCard('Acne Severity Scale', '1 to 10 Scale', Icons.linear_scale_rounded, primaryColor),
            const SizedBox(height: 16),
            _buildInfoCard('Classes Trained', 'Pimple (Single-class)', Icons.label_important_outline_rounded, primaryColor),
            const SizedBox(height: 30),
            
            // Informative note for Viva
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: primaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Viva Note: Acne severity is evaluated via a hybrid score combining pimple count, confidence, and detection area ratio: Clear (1-2), Mild (3-4), Moderate (5-7), and Severe (8-10).',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A211D),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
