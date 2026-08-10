import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'What is Derma Sense AI?',
      'answer': 'Derma Sense AI is a personal skin wellness companion. It uses an advanced computer vision model (YOLOv8) to analyze skin images, detect active acne (pimples), and evaluate severity to help you track your skin journey.',
      'category': 'General',
    },
    {
      'question': 'Is this app a substitute for a doctor?',
      'answer': 'No. Derma Sense AI is designed for educational, informational, and personal tracking purposes only. It does not provide medical diagnoses, treatment, or professional medical advice. Always consult a board-certified dermatologist for medical concerns.',
      'category': 'General',
    },
    {
      'question': 'How is acne severity calculated?',
      'answer': 'Severity is determined using a hybrid score of active pimple count, detection confidence, and area ratio coverage:\n• Clear: 1 - 2/10 severity\n• Mild: 3 - 4/10 severity\n• Moderate: 5 - 7/10 severity\n• Severe: 8 - 10/10 severity',
      'category': 'Acne Detection',
    },
    {
      'question': 'Why is my scan failing to connect?',
      'answer': 'Please verify that your Flask backend server is running and accessible. Go to Profile > Server Connection Config and make sure you have entered the correct local IP address (e.g. 192.168.x.x) or active Ngrok URL.',
      'category': 'Connection',
    },
    {
      'question': 'Is my skin data secure?',
      'answer': 'Yes, we take privacy very seriously. Your uploaded scans are saved securely in Firebase Storage and Firestore. They are linked privately to your authenticated user account and are not shared with any third parties.',
      'category': 'General',
    },
    {
      'question': 'How can I get the best scan results?',
      'answer': 'For the most accurate detection: \n1. Ensure good, natural lighting (avoid harsh shadows).\n2. Keep your face centered, clean, and parallel to the camera.\n3. Hold the camera steady and focus on the affected areas.',
      'category': 'Acne Detection',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesSearch = faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _copySupportEmail() {
    Clipboard.setData(const ClipboardData(text: 'support@dermasense.ai'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support email copied to clipboard!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF20D284),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF20D284);
    const bgColor = Color(0xFFF9FCFA);
    const textColor = Color(0xFF1A211D);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Help Center',
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
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.03)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search topics, FAQs...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                      prefixIcon: const Icon(Icons.search_rounded, color: primaryColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', 'General', 'Acne Detection', 'Connection'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              color: isSelected ? Colors.white : textColor.withOpacity(0.6),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: primaryColor,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected ? Colors.transparent : Colors.black.withOpacity(0.06),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // FAQ list
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 60,
                          color: textColor.withOpacity(0.2),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No FAQ found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.03)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.01),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            leading: const Icon(
                              Icons.question_answer_outlined,
                              color: primaryColor,
                              size: 20,
                            ),
                            title: Text(
                              faq['question']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                            children: [
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  faq['answer']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                    color: textColor.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Footer: Contact support
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Still need help?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Our support team is available 24/7",
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _copySupportEmail,
                    icon: const Icon(Icons.email_outlined, color: Colors.white),
                    label: const Text(
                      'Copy Support Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
