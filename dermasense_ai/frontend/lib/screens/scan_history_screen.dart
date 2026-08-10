import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, String scanId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Log', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this scan from your history? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('scans')
                    .doc(scanId)
                    .delete();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Clear History', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete all scans? This will permanently wipe your progress tracking logs.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final scansRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('scans');
                final query = await scansRef.get();
                final batch = FirebaseFirestore.instance.batch();
                for (var doc in query.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Clear All', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSeverityBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildScanImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.grey, size: 28),
      );
    }

    final isNetwork = imageUrl.startsWith('http://') || imageUrl.startsWith('https://') || imageUrl.startsWith('blob:');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        height: 70,
        child: (isNetwork || kIsWeb)
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              )
            : Image.file(
                File(imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[100],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    const bgColor = Color(0xFFF9FCFA);
    const textColor = Color(0xFF1A211D);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          title: const Text('Scan History', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Please log in to view scan history.',
            style: TextStyle(color: textColor),
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('scans')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              title: const Text('Scan History', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          );
        }

        final scans = snapshot.data?.docs ?? [];

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            centerTitle: true,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan History',
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (scans.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${scans.length} Total Scans',
                    style: TextStyle(
                      color: textColor.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (scans.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded, color: textColor),
                  tooltip: 'Clear History',
                  onPressed: () => _confirmClearAll(context),
                ),
            ],
          ),
          body: scans.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        size: 80,
                        color: textColor.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No past scans found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan your skin to start tracking logs!',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: scans.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // 1. Build Progress Summary Card
                      if (scans.length >= 2) {
                        final latestScan = scans.first.data() as Map<String, dynamic>;
                        final oldestScan = scans.last.data() as Map<String, dynamic>;

                        final latestCount = latestScan['pimpleCount'] ?? latestScan['acneCount'] ?? 0;
                        final oldestCount = oldestScan['pimpleCount'] ?? oldestScan['acneCount'] ?? 0;

                        String progressLabel = "Stable";
                        Color progressColor = Colors.grey;
                        IconData progressIcon = Icons.trending_flat_rounded;
                        String progressMsg = "Acne count stable.";

                        if (latestCount < oldestCount) {
                          progressLabel = "Improved ↓";
                          progressColor = const Color(0xFF20D284);
                          progressIcon = Icons.trending_down_rounded;
                          progressMsg = "${oldestCount - latestCount} fewer pimples detected compared to your first scan.";
                        } else if (latestCount > oldestCount) {
                          progressLabel = "Needs Attention ↑";
                          progressColor = const Color(0xFFFF4A8D);
                          progressIcon = Icons.trending_up_rounded;
                          progressMsg = "${latestCount - oldestCount} more pimples detected compared to your first scan.";
                        }

                        return Container(
                          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 8),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: progressColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: progressColor.withOpacity(0.25), width: 1.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: progressColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(progressIcon, color: progressColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Skin Progress",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF6B7A72),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      progressLabel,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: progressColor,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      progressMsg,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: textColor.withOpacity(0.7),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      "$oldestCount ➜ $latestCount",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: textColor.withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Show single scan message card
                        return Container(
                          margin: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: primaryColor.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insights_rounded, color: primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "First scan log saved! Future scans will display progress updates here.",
                                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }

                    // Scan indices are shifted by 1
                    final scanDoc = scans[index - 1];
                    final scan = scanDoc.data() as Map<String, dynamic>;
                    final String scanId = scanDoc.id;

                    final int severityScore = scan['severityScore'] ?? 1;
                    final String severityLabel = scan['severity'] ?? scan['severityLabel'] ?? 'Clear';
                    final int acneCount = scan['pimpleCount'] ?? scan['acneCount'] ?? scan['pimplesCount'] ?? 0;
                    final double confidenceVal = double.tryParse((scan['confidence'] ?? 0.0).toString()) ?? 0.0;
                    final String imageUrl = scan['imageUrl'] ?? '';
                    final String advice = scan['guidanceAdvice'] ?? '';
                    final List<dynamic> safetyWarnings = scan['safetyWarnings'] ?? [];
                    
                    final dynamic ts = scan['timestamp'] ?? scan['createdAt'];
                    Timestamp? createdAt = ts is Timestamp ? ts : null;
                    String dateStr = 'Unknown Date';
                    if (createdAt != null) {
                      final date = createdAt.toDate();
                      final day = date.day.toString().padLeft(2, '0');
                      final month = date.month.toString().padLeft(2, '0');
                      final year = date.year;
                      final hour = date.hour.toString().padLeft(2, '0');
                      final minute = date.minute.toString().padLeft(2, '0');
                      dateStr = '$day/$month/$year at $hour:$minute';
                    }

                    Color severityColor;
                    if (severityLabel == 'Clear' || severityLabel == 'Mild') {
                      severityColor = const Color(0xFF20D284);
                    } else if (severityLabel == 'Moderate') {
                      severityColor = const Color(0xFFFFB020);
                    } else {
                      severityColor = const Color(0xFFFF4A8D);
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/results', arguments: {
                                'data': {
                                  'acneCount': acneCount,
                                  'severityScore': severityScore,
                                  'severityLabel': severityLabel,
                                  'confidence': confidenceVal,
                                  'recommendations': {
                                    'advice': advice,
                                    'safety_warnings': safetyWarnings,
                                  },
                                },
                                'imagePath': imageUrl,
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Image Thumbnail
                                  _buildScanImage(imageUrl),
                                  const SizedBox(width: 16),
                                  // Scan details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.4),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            _buildSeverityBadge(severityLabel, severityColor),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$acneCount Estimated Pimples',
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.6),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Detection Confidence ${(confidenceVal * 100).toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.4),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
                                    onPressed: () => _confirmDelete(context, scanId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
