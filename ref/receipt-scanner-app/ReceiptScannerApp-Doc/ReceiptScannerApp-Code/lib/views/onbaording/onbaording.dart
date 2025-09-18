import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Assuming you have a MainScreen to navigate to after onboarding.
// If not, you can create a simple placeholder screen.
import '../mainscrens/mainscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Rock Scanner', // UPDATED APP TITLE
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const OnboardingScreen(),
    );
  }
}

class OnboardingContent {
  final String imagePath;
  final String title;
  final String description;

  const OnboardingContent(
      {required this.imagePath,
        required this.title,
        required this.description});
}

// ⭐️ UPDATED TITLES AND DESCRIPTIONS FOR PET EMOTION DETECTION ⭐️
final List<OnboardingContent> onboardingContents = [
  const OnboardingContent(
    imagePath: 'images/o1.png',
    title: 'Scan Receipts\nwith Ease',
    description:
    'Capture receipts instantly with your camera. Our AI extracts details like vendor, date, and amount automatically.',
  ),
  const OnboardingContent(
    imagePath: 'images/o2.png',
    title: 'Track Your\nExpenses',
    description:
    'Organize all your spending in one place. Categorize transactions, monitor budgets, and stay on top of your finances.',
  ),
  const OnboardingContent(
    imagePath: 'images/o3.png',
    title: 'Manage Reports\nEffortlessly',
    description:
    'Generate detailed expense reports in seconds. Export and share them anytime for personal, business, or tax purposes.',
  ),
];


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _skipToEnd() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const MainScreen()));
  }

  void _nextPage() {
    if (_currentIndex < onboardingContents.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      // This is the last page, navigate to MainScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip Button
            Positioned(
              top: 20,
              right: 20,
              child: TextButton(
                onPressed: _skipToEnd,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: Color(0xFF6A1B9A), // Updated color
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  // Image Section
                  Expanded(
                    flex: 5,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: onboardingContents.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Updated Image display to better suit rectangular images
                              ClipRRect(
                                borderRadius: BorderRadius.circular(180.0),

                                child: Image.asset(
                                  onboardingContents[index].imagePath,
                                  height: 275, // Adjust height as needed
                                  fit: BoxFit.cover,
                                  width: 275,

                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Text Content
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0,vertical: 10),
                      child: Column(
                        children: [
                          Text(
                            onboardingContents[_currentIndex].title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color:Color(0xFF6A1B9A), // Updated color
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            onboardingContents[_currentIndex].description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF757575),
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Page Indicators and Button
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          onboardingContents.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Color(0xFF6A1B9A) // Updated color
                                  : const Color(0xFFE0E0E0),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 30, 40, 40),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Color(0xFF6A1B9A), // Updated color
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            child: Text(
                              _currentIndex == onboardingContents.length - 1
                                  ? 'Get Started'
                                  : 'Continue',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}