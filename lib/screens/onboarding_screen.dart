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

  void _onQuickScan() {
    Provider.of<AppProvider>(context, listen: false).setGuestUser();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isTwi = provider.language == 'Twi';

    final List<OnboardingData> pages = [
      OnboardingData(
        title: isTwi ? 'AI Nhwehwɛmu\na Ɛdi Mu' : 'Precision AI\nDetection',
        subtitle: isTwi ? 'Hu Yadeɛ No Ntɛm' : 'Identify Diseases Instantly',
        description: isTwi 
            ? 'Yɛn AI mmoawa nhwehwɛmu adwuma yi hu kabeji yadeɛ nyinaa bɛyɛ 95% wɔ sikani kakra bi mu.' 
            : 'Our advanced neural networks detect cabbage diseases with over 95% accuracy in seconds.',
        imagePath: 'assets/images/c2.jpg',
        color: const Color(0xFF4CAF50),
      ),
      OnboardingData(
        title: isTwi ? 'Afutuo Pa firi\nAnigyeɛ Mu' : 'Expert Field\nAdvice',
        subtitle: isTwi ? 'Akuafoɔ Mmoa' : 'Smart Farming Assistant',
        description: isTwi 
            ? 'Nya ayaresa ne akwan a wobɛfa so asiw yadeɛ kwan wɔ w’afuo mu.' 
            : 'Receive localized treatment plans and preventive measures tailored for your farm.',
        imagePath: 'assets/images/c3.jpg',
        color: const Color(0xFFFF9800),
      ),
      OnboardingData(
        title: isTwi ? 'Nhwehwɛmu a\nIntanɛt Nni Ho' : 'Reliable Offline\nAnalysis',
        subtitle: isTwi ? 'Intanɛt Hia' : 'No Internet Needed',
        description: isTwi 
            ? 'Scan wo nnɔbae no wɔ baabiara, mpo mmeae a intanɛt nni hɔ koraa.' 
            : 'Scan your crops anywhere, even in the most remote fields. All AI models run on your device.',
        imagePath: 'assets/images/c4.jpg',
        color: const Color(0xFF2196F3),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (int page) => setState(() => _currentPage = page),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    pages[index].imagePath,
                    fit: BoxFit.cover,
                  ),
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
                        child: Text(
                          isTwi ? 'Twa mu' : 'Skip',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
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
                            color: pages[_currentPage].color.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: pages[_currentPage].color.withOpacity(0.5)),
                          ),
                          child: Text(
                            pages[_currentPage].subtitle.toUpperCase(),
                            style: TextStyle(
                              color: pages[_currentPage].color,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pages[_currentPage].title,
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
                          pages[_currentPage].description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          pages.length,
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
                      GestureDetector(
                        onTap: () {
                          if (_currentPage == pages.length - 1) {
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
                            color: pages[_currentPage].color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: pages[_currentPage].color.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentPage == pages.length - 1 ? Icons.done_rounded : Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: TextButton(
                      onPressed: _onQuickScan,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 13),
                          children: [
                            TextSpan(
                              text: isTwi ? 'Woyɛ foforɔ? ' : 'New here? ',
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                            ),
                            TextSpan(
                              text: isTwi ? 'Yɛ Nhwehwɛmu Ntɛm' : 'Try Quick Scan',
                              style: const TextStyle(
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
