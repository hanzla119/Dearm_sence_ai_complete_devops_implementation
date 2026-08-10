import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String userName = "User";
  Stream<QuerySnapshot>? _scansStream;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // If it's a Google user, try user.displayName first
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          setState(() {
            userName = user.displayName!.split(' ')[0]; // Use first name
          });
        }
        
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data();
          final dbName = data?['name'] as String?;
          if (dbName != null && dbName.isNotEmpty) {
            setState(() {
              userName = dbName.split(' ')[0]; // Get first name
            });
          }
        }

        // Initialize reactive Firestore scans stream
        setState(() {
          _scansStream = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('scans')
              .orderBy('createdAt', descending: true)
              .snapshots();
        });
      }
    } catch (e) {
      debugPrint("Error loading user data / scans: $e");
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning";
    if (hour < 17) return "Good Afternoon";
    return "Good Evening";
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Recent";
    final difference = DateTime.now().difference(timestamp.toDate());
    if (difference.inDays >= 1) return "${difference.inDays} days ago";
    if (difference.inHours >= 1) return "${difference.inHours} hours ago";
    if (difference.inMinutes >= 1) return "${difference.inMinutes} mins ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    const bgColor = Color(0xFFFBFDFB);
    const textColor = Color(0xFF1A211D);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Section (Greetings and Action Buttons)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_getGreeting()}, $userName",
                        style: const TextStyle(
                          color: Color(0xFF6B7A72),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ready to Glow?',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderIcon(Icons.notifications_none_rounded, () {
                        Navigator.pushNamed(context, '/notifications');
                      }),
                      const SizedBox(width: 12),
                      _buildHeaderIcon(Icons.person_outline_rounded, () {
                        Navigator.pushNamed(context, '/profile');
                      }),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 32),
              
              // 2. Main CTA Scanner Card (minHeight 180, camera icon)
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/scan'),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    minHeight: 180,
                  ),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryColor, Color(0xFF10B981)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.22),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'AI SKIN SCANNER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Scan Any Area',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Detect acne on any part of the body',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.document_scanner_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              
              // 3. Today's Insights Section
              const Text(
                "Today's Insights",
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/funfact'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9EE),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFFFEAB8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFEAB8).withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF1C6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tips_and_updates_outlined,
                          color: Color(0xFFD97706),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FunFacts Reminders',
                              style: TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Did you know water helps...',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFFD97706),
                        size: 28,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              
              // 4. StreamBuilder content (Recent Scan, Skin Progress)
              StreamBuilder<QuerySnapshot>(
                stream: _scansStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    );
                  }

                  final scans = snapshot.data?.docs ?? [];

                  if (scans.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Track Your Journey",
                          style: TextStyle(
                            color: textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.insights_rounded, color: primaryColor, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start Tracking Progress',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Log your first skin scan to see history and acne tracking details.',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildConsultCard(context, null),
                      ],
                    );
                  }

                  final latestScan = scans.first.data() as Map<String, dynamic>;
                  Widget progressCard = const SizedBox.shrink();

                  if (scans.length >= 2) {
                    final oldestScan = scans.last.data() as Map<String, dynamic>;
                    final latestCount = latestScan['pimpleCount'] ?? latestScan['acneCount'] ?? 0;
                    final oldestCount = oldestScan['pimpleCount'] ?? oldestScan['acneCount'] ?? 0;
                    progressCard = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildSkinProgressCard(latestCount, oldestCount),
                      ],
                    );
                  } else {
                    progressCard = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        _buildSkinProgressCard(-1, -1),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tracking & Progress",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRecentScanCard(latestScan),
                      progressCard,
                      const SizedBox(height: 24),
                      _buildConsultCard(context, latestScan),
                    ],
                  );
                },
              ),
              const SizedBox(height: 36),

              // 5. Quick Actions Row
              const Text(
                "Quick Actions",
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(context),
            ],
          ),
        ),
      ),
      
      // 6. Bottom Navigation Bar (History label and History icon)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF9CA3AF),
          currentIndex: 0, // Home active
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: primaryColor),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline_rounded),
              activeIcon: Icon(Icons.people_rounded, color: primaryColor),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              activeIcon: Icon(Icons.history, color: primaryColor),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, color: primaryColor),
              label: 'Profile',
            ),
          ],
          onTap: (index) {
            if (index == 0) return; // Already on Home
            if (index == 1) {
              Navigator.pushNamed(context, '/community');
            } else if (index == 2) {
              Navigator.pushNamed(context, '/history');
            } else if (index == 3) {
              Navigator.pushNamed(context, '/profile');
            }
          },
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(color: Colors.black.withOpacity(0.05)),
        ),
        child: Icon(icon, color: const Color(0xFF1A211D), size: 22),
      ),
    );
  }

  Widget _buildRecentScanCard(Map<String, dynamic> scan) {
    final severity = scan['severity'] ?? scan['severityLabel'] ?? 'Clear';
    final count = scan['pimpleCount'] ?? scan['acneCount'] ?? 0;
    final dynamic ts = scan['timestamp'] ?? scan['createdAt'];
    final timestamp = ts is Timestamp ? ts : null;
    final dateStr = _timeAgo(timestamp);

    Color severityColor = const Color(0xFF20D284);
    if (severity == 'Moderate') severityColor = const Color(0xFFFFB020);
    if (severity == 'Severe') severityColor = const Color(0xFFFF4A8D);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.spa_outlined, color: severityColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Scan',
                  style: TextStyle(
                    color: Color(0xFF6B7A72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$severity • $count Pimples',
                  style: const TextStyle(
                    color: Color(0xFF1A211D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinProgressCard(int latestCount, int previousCount) {
    final difference = previousCount - latestCount;
    String status = "Stable";
    String description = "No change in pimple count";
    Color progressColor = Colors.grey;
    IconData icon = Icons.trending_flat_rounded;

    if (latestCount == -1 && previousCount == -1) {
      status = "Baseline Established";
      description = "Take another scan in a few days to track progress!";
      progressColor = const Color(0xFF20D284);
      icon = Icons.spa_outlined;
    } else if (difference > 0) {
      status = "Improved ↑";
      description = "$difference fewer pimples than baseline scan";
      progressColor = const Color(0xFF20D284);
      icon = Icons.trending_down_rounded;
    } else if (difference < 0) {
      status = "Needs Attention ↓";
      description = "${difference.abs()} more pimples than baseline scan";
      progressColor = const Color(0xFFFF4A8D);
      icon = Icons.trending_up_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: progressColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Skin Progress',
                  style: TextStyle(
                    color: Color(0xFF6B7A72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultCard(BuildContext context, Map<String, dynamic>? latestScan) {
    Map<String, dynamic>? args;
    if (latestScan != null) {
      args = {
        'severityScore': latestScan['severityScore'] ?? 1,
        'severityLabel': latestScan['severity'] ?? latestScan['severityLabel'] ?? 'Clear',
        'acneCount': latestScan['pimpleCount'] ?? latestScan['acneCount'] ?? 0,
      };
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/book-consultation', arguments: args),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.black.withOpacity(0.03)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8F00).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: Color(0xFFFF8F00),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Telederma',
                    style: TextStyle(
                      color: Color(0xFF6B7A72),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Consult Now',
                    style: TextStyle(
                      color: Color(0xFF1A211D),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Get a professional skin evaluation and treatment plan from a certified dermatologist.',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF9CA3AF),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildActionItem(context, 'Help Center', Icons.help_outline_rounded, const Color(0xFFE5F7ED), const Color(0xFF20D284), '/help-center'),
        _buildActionItem(context, 'Feedback', Icons.chat_bubble_outline_rounded, const Color(0xFFE8F0FE), const Color(0xFF1A73E8), '/feedback'),
        _buildActionItem(context, 'Daily Tips', Icons.tips_and_updates_outlined, const Color(0xFFFEF3C7), const Color(0xFFD97706), '/funfact'),
        _buildActionItem(context, 'Notifications', Icons.notifications_none_rounded, const Color(0xFFF3E8FF), const Color(0xFF9333EA), '/notifications'),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, String label, IconData icon, Color bgColor, Color iconColor, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: SizedBox(
        width: 74,
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF1A211D),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
