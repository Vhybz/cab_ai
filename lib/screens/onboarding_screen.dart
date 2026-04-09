import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'dart:ui';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Precision AI\nDetection',
      subtitle: 'Identify Diseases Instantly',
      description: 'Our advanced neural networks detect cabbage diseases with over 95% accuracy in seconds.',
      imagePath: 'assets/images/c2.jpg',
      color: const Color(0xFF4CAF50),
    ),
    OnboardingData(
      title: 'Expert Field\nAdvice',
      subtitle: 'Smart Farming Assistant',
      description: 'Receive localized treatment plans and preventive measures tailored for your farm.',
      imagePath: 'assets/images/c3.jpg',
      color: const Color(0xFFFF9800),
    ),
    OnboardingData(
      title: 'Reliable Offline\nAnalysis',
      subtitle: 'No Internet Needed',
      description: 'Scan your crops anywhere, even in the most remote fields. All AI models run on your device.',
      imagePath: 'assets/images/c4.jpg',
      color: const Color(0xFF2196F3),
    ),
  ];

  void _onQuickScan() {
    Provider.of<AppProvider>(context, listen: false).setGuestUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Cinematic Background with Smooth Transitions
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            physics: const BouncingScrollPhysics(), // Allows swiping both ways
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _pages[index].imagePath,
                    fit: BoxFit.cover,
                  ),
                  // Strong dark gradient to ensure text visibility over green images
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.7),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. Fixed Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button to allow manual navigation back
                      _currentPage > 0 
                        ? IconButton(
                            onPressed: () => _pageController.previousPage(
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutQuart,
                            ),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                          )
                        : const SizedBox(width: 40),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  
                  // Text Content with Animation
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.1),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      key: ValueKey<int>(_currentPage),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _pages[_currentPage].color.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _pages[_currentPage].color.withOpacity(0.5)),
                          ),
                          child: Text(
                            _pages[_currentPage].subtitle.toUpperCase(),
                            style: TextStyle(
                              color: _pages[_currentPage].color,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _pages[_currentPage].title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 15, offset: Offset(0, 4)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pages[_currentPage].description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95), // Highly visible
                            fontSize: 16,
                            height: 1.6,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Bottom Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicators (Clickable)
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => GestureDetector(
                            onTap: () => _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutQuart,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(right: 8),
                              height: 6,
                              width: _currentPage == index ? 32 : 6,
                              decoration: BoxDecoration(
                                color: _currentPage == index ? Colors.white : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Progress FAB Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage == _pages.length - 1) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 800),
                              curve: Curves.easeOutQuart,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            color: _pages[_currentPage].color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage].color.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentPage == _pages.length - 1 ? Icons.done_rounded : Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Quick Scan Link
                  Center(
                    child: TextButton(
                      onPressed: _onQuickScan,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'New here? ',
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                            const TextSpan(
                              text: 'Try Quick Scan',
                              style: TextStyle(
                                color: Colors.white, 
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String description;
  final String imagePath;
  final Color color;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imagePath,
    required this.color,
  });
}
