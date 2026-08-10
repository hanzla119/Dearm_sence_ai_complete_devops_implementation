import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
  }

  String formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown time";
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$day/$month/$year at $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    const bgColor = Color(0xFFF9FCFA);
    const textColor = Color(0xFF1A211D);

    if (user == null) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(child: Text("Please login to view notifications.", style: TextStyle(color: textColor))),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("scans")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.black.withOpacity(0.04)),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.waving_hand_rounded, color: primaryColor),
                      ),
                      title: const Text(
                        "Welcome to DermaSense AI",
                        style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Start your first acne scan to receive personalized skin notifications.",
                          style: TextStyle(color: textColor.withOpacity(0.6), height: 1.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          final scans = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final data = scans[index].data() as Map<String, dynamic>;

              final String severity = data["severityLabel"] ?? "Clear";
              final int pimpleCount = data["acneCount"] ?? 0;
              final timestamp = data["createdAt"] as Timestamp?;

              Color severityColor;
              if (severity == 'Clear' || severity == 'Mild') {
                severityColor = const Color(0xFF20D284);
              } else if (severity == 'Moderate') {
                severityColor = const Color(0xFFFFB020);
              } else {
                severityColor = const Color(0xFFFF4A8D);
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.black.withOpacity(0.04)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active_rounded, color: severityColor),
                    ),
                    title: Text(
                      "Scan Result: Severity $severity",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: textColor),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        "Estimated pimples: $pimpleCount\nTime: ${formatDate(timestamp)}",
                        style: TextStyle(color: textColor.withOpacity(0.6), height: 1.4, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
