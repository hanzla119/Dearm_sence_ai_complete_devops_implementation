import 'package:flutter/material.dart';

class FunFactScreen extends StatefulWidget {
  const FunFactScreen({super.key});

  @override
  State<FunFactScreen> createState() => _FunFactScreenState();
}

class _FunFactScreenState extends State<FunFactScreen> {
  int currentIndex = 0;

  final List<String> facts = [
    "Acne is not caused by dirty skin. Over-washing can irritate the skin and make acne worse.",
    "Toothpaste should not be used on pimples because it can cause dryness, irritation, and burns.",
    "Sunscreen is important even for acne-prone skin. Choose non-comedogenic sunscreen.",
    "Drinking water supports skin health, but hydration alone does not cure acne.",
    "Lack of sleep can increase stress hormones, which may worsen acne breakouts.",
    "Picking or squeezing pimples can cause scars, dark spots, and infection.",
    "Acne can appear on the face, chest, back, shoulders, and other body areas.",
    "Some skincare products can clog pores. Always check for non-comedogenic labels.",
    "Stress does not directly cause acne, but it can make existing acne worse.",
    "Consistent skincare is more effective than frequently changing products.",
  ];

  void nextFact() {
    setState(() {
      currentIndex = (currentIndex + 1) % facts.length;
    });
  }

  void previousFact() {
    setState(() {
      currentIndex = (currentIndex - 1 + facts.length) % facts.length;
    });
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
          "Daily Skincare Fact",
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey<int>(currentIndex),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                  border: Border.all(color: Colors.black.withOpacity(0.03)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD14A).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          size: 50,
                          color: Color(0xFFD6A000),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Fact ${currentIndex + 1} of ${facts.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD6A000),
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        facts[currentIndex],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: primaryColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: previousFact,
                      icon: const Icon(Icons.arrow_back_rounded, color: primaryColor),
                      label: const Text(
                        "Previous",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: nextFact,
                      icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                      label: const Text(
                        "Next",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
