import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String? age;
  String? gender;
  String? photoUrl;
  bool _profileLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          name = data?['name'] as String?;
          age = data?['age']?.toString();
          gender = data?['gender'] as String?;
          photoUrl = data?['photoUrl'] as String?;
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    setState(() => _profileLoading = true);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(image.path));
      }

      final downloadUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        photoUrl = downloadUrl;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
      }
    } catch (e) {
      debugPrint("Photo Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _profileLoading = false);
      }
    }
  }

  void _showEditProfileDialog() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final nameController = TextEditingController(text: name);
    final ageController = TextEditingController(text: age);
    
    // Default to existing gender or 'Male' if empty
    String selectedGender = (gender != null && gender!.isNotEmpty) ? gender! : 'Male';
    final gendersList = ['Male', 'Female', 'Prefer not to say'];
    if (!gendersList.contains(selectedGender)) {
      selectedGender = 'Male';
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.person_outline, color: Color(0xFF20D284)),
                  SizedBox(width: 12),
                  Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedGender,
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                      items: gendersList.map((g) {
                        return DropdownMenuItem(value: g, child: Text(g));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedGender = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF20D284),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final newName = nameController.text.trim();
                    final newAge = ageController.text.trim();

                    if (newName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your name')),
                      );
                      return;
                    }

                    final ageInt = int.tryParse(newAge);
                    if (ageInt == null || ageInt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid numeric age')),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .set({
                        'name': newName,
                        'age': ageInt,
                        'gender': selectedGender,
                        'email': user.email,
                        'photoUrl': photoUrl,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }, SetOptions(merge: true));

                      setState(() {
                        name = newName;
                        age = ageInt.toString();
                        gender = selectedGender;
                      });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!')),
                        );
                      }
                    } catch (e) {
                      debugPrint("Profile Update Error: $e");
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update profile: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'No active user';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _profileLoading ? null : _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF20D284),
                    backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: (photoUrl == null || photoUrl!.isEmpty)
                        ? (_profileLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Icon(Icons.person, size: 50, color: Colors.white))
                        : (_profileLoading
                            ? Container(
                                color: Colors.black45,
                                child: const CircularProgressIndicator(color: Colors.white),
                              )
                            : null),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _profileLoading ? null : _pickAndUploadImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF20D284),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              name?.isNotEmpty == true ? name! : 'DermaSense User',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 40),
          ListTile(
            leading: const Icon(Icons.email, color: Color(0xFF20D284)),
            title: const Text('Account Email', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(email, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.badge, color: Color(0xFF20D284)),
            title: const Text('Profile Details', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(
              'Age: ${age ?? "Not Set"}   |   Gender: ${gender ?? "Not Set"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            trailing: const Icon(Icons.edit, size: 18),
            onTap: _showEditProfileDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history_rounded, color: Color(0xFF20D284)),
            title: const Text('Scan History', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: const Text('View & Track Past Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined, color: Color(0xFF20D284)),
            title: const Text('Notifications', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: const Text('Recent Alerts & Updates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.psychology_rounded, color: Color(0xFF20D284)),
            title: const Text('About AI', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: const Text('Model Parameters & Metadata', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => Navigator.pushNamed(context, '/about-ai'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF20D284)),
            title: const Text('Help Center', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: const Text('FAQs & Support Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => Navigator.pushNamed(context, '/help-center'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.rate_review_rounded, color: Color(0xFF20D284)),
            title: const Text('Feedback', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: const Text('Share Experience & Ratings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => Navigator.pushNamed(context, '/feedback'),
          ),
          const Divider(),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }
}
