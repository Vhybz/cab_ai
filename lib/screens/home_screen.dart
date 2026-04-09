import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/app_provider.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'chatbot_screen.dart';
import 'schedule_screen.dart';
import 'weather_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF9FBF9),
      drawer: _buildRefinedDrawer(context, colorScheme),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen())),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.forum_rounded, size: 28),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // 1. Sleek Floating AppBar
                  SliverAppBar(
                    expandedHeight: 120.0,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: isDark 
                        ? theme.scaffoldBackgroundColor.withOpacity(0.7) 
                        : Colors.white.withOpacity(0.7),
                    surfaceTintColor: Colors.transparent,
                    leading: Builder(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.menu_open_rounded, color: colorScheme.primary, size: 24),
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : colorScheme.primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_outline_rounded, color: colorScheme.primary, size: 24),
                          ),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                        ),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        provider.tr('DASHBOARD'),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 3,
                        ),
                      ),
                      background: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2. Greeting Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.language == 'Twi' ? 'Maakye, ${provider.userName} 👋' : 'Hey ${provider.userName} 👋',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -0.5,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      provider.tr('Scan your leaves for health status.'),
                                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Live Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(provider.tr('LIVE'), style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3. Advanced Slideshow
                          const LeafSlideshow(),
                          const SizedBox(height: 24),

                          // 4. Compact Status Row
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherScreen())),
                                  borderRadius: BorderRadius.circular(20),
                                  child: _buildCompactMetric(context, Icons.wb_sunny_rounded, '28°C', provider.tr('Sunny')),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _buildCompactMetric(context, Icons.analytics_rounded, provider.history.length.toString(), provider.tr('Scans'))),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // 5. Dynamic Section: Today's Smart Task
                          _buildDynamicScheduleCard(context, provider),
                          const SizedBox(height: 32),

                          // 6. Action Tools
                          Text(
                            provider.tr('Diagnosis Tools'),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: _buildRefinedAction(
                                  context,
                                  provider.tr('Camera'),
                                  Icons.camera_alt_rounded,
                                  colorScheme.primary,
                                  () async {
                                    await provider.pickImage(ImageSource.camera);
                                    if (context.mounted && provider.currentPrediction != null) {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildRefinedAction(
                                  context,
                                  provider.tr('Gallery'),
                                  Icons.photo_library_rounded,
                                  colorScheme.secondary,
                                  () async {
                                    await provider.pickImage(ImageSource.gallery);
                                    if (context.mounted && provider.currentPrediction != null) {
                                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),

                          // 7. Recent Activity
                          if (provider.history.isNotEmpty) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(provider.tr('Recent Scans'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                TextButton(
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                                  child: Text(provider.tr('View all')),
                                ),
                              ],
                            ),
                            _buildCompactHistoryList(context, provider),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              if (provider.isLoading)
                _buildAnalysisOverlay(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalysisOverlay(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.green,
                  highlightColor: Colors.greenAccent,
                  child: const Icon(Icons.eco_rounded, size: 80),
                ),
                const SizedBox(height: 24),
                Shimmer.fromColors(
                  baseColor: isDark ? Colors.white : Colors.black,
                  highlightColor: Colors.grey,
                  child: Text(
                    provider.tr('ANALYZING LEAF...'),
                    style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 8),
                Text(provider.tr('Our AI is detecting diseases'), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicScheduleCard(BuildContext context, AppProvider provider) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final suggestion = provider.getSuggestedActivity(DateTime.now());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        provider.tr('Daily Recommendation'), 
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen())),
                child: Text(provider.tr('Plan More'), style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(
                  suggestion.contains('Water') || suggestion.contains('Nsuo') ? Icons.water_drop_rounded : 
                  suggestion.contains('Scan') ? Icons.qr_code_scanner_rounded : 
                  Icons.agriculture_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(provider.tr('Based on crop cycle'), style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetric(BuildContext context, IconData icon, String value, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedAction(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHistoryList(BuildContext context, AppProvider provider) {
    final history = provider.history;
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length > 3 ? 3 : history.length,
      itemBuilder: (context, index) {
        final scan = history[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: ListTile(
            onTap: () {
              provider.setCurrentPrediction(scan);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Hero(
              tag: scan.imagePath,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(scan.imagePath), width: 50, height: 50, fit: BoxFit.cover),
              ),
            ),
            title: Text(scan.diseaseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
            subtitle: Text(DateFormat('MMM dd, hh:mm a').format(scan.dateTime), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildRefinedDrawer(BuildContext context, ColorScheme colorScheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF121212), const Color(0xFF1A1A1A)] 
              : [const Color(0xFF1B2E1C), const Color(0xFF2E4D2F)],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 40, 
                        backgroundColor: Colors.white10, 
                        backgroundImage: AssetImage('assets/images/c10.jpg'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.userName == 'Guest' ? provider.tr('Guest User') : provider.userName, 
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.userName == 'Guest' ? provider.tr('Standard Access') : provider.tr('Pro Farmer'), 
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, indent: 24, endIndent: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _drawerTile(context, Icons.dashboard_rounded, provider.tr('Home'), null, true),
                    _drawerTile(context, Icons.cloud_rounded, provider.tr('Weather'), const WeatherScreen(), false),
                    _drawerTile(context, Icons.event_note_rounded, provider.tr('Schedule'), const ScheduleScreen(), false),
                    _drawerTile(context, Icons.insights_rounded, provider.tr('Analytics'), const AnalyticsScreen(), false),
                    _drawerTile(context, Icons.history_edu_rounded, provider.tr('History'), const HistoryScreen(), false),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Divider(color: Colors.white10),
                    ),
                    _drawerTile(context, Icons.settings_suggest_rounded, provider.tr('Settings'), const SettingsScreen(), false),
                    _drawerTile(context, Icons.contact_support_rounded, provider.tr('Help & About'), const AboutScreen(), false),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        provider.tr('Logout'), 
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, Widget? target, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          icon, 
          color: isSelected ? Colors.greenAccent : Colors.white60, 
          size: 22
        ),
        title: Text(
          label, 
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70, 
            fontSize: 15, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          Navigator.pop(context);
          if (target != null) Navigator.push(context, MaterialPageRoute(builder: (context) => target));
        },
      ),
    );
  }
}

class LeafSlideshow extends StatefulWidget {
  const LeafSlideshow({super.key});

  @override
  State<LeafSlideshow> createState() => _LeafSlideshowState();
}

class _LeafSlideshowState extends State<LeafSlideshow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> _assetImages = [
    'assets/images/c1.jpg',
    'assets/images/c2.jpg',
    'assets/images/c3.jpg',
    'assets/images/c4.jpg',
    'assets/images/c5.jpg',
    'assets/images/c6.jpg',
    'assets/images/c7.jpg',
    'assets/images/c8.jpg',
    'assets/images/c9.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _assetImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage, 
          duration: const Duration(milliseconds: 800), 
          curve: Curves.easeInOutQuint,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AppProvider>(context);

    final List<String> tips = provider.language == 'Twi' ? [
      'Bere nyinaa scan nhaban no sɛnea ɛbɛyɛ a wobɛhu yadeɛ ntɛm.',
      'Yadeɛ ho nhwehwɛmu ntɛm tumi ma nnɔbae pii si so bɛyɛ 40%.',
      'Bere nyinaa kɔ afuo mu hwɛ nnɔbae no sɛnea ɛbɛyɛ a yadeɛ biara remma.',
      'Sɛ wohu yadeɛ ntɛm a, ayaresa nso yɛ mmerɛ na ne bo nso yɛ fo.',
      'Scan wo kabeji dabiara dabiara sɛnea ɛbɛyɛ a ɛho bɛyɛ den.',
      'Sɛ wohu sɛ yadeɛ bi reba a, yɛ ho adwuma ntɛm na woantumi anhwere wo nnɔbae.',
      'Nhwehwɛmu a ɛkɔ so bere nyinaa ma wonya nnɔbae pa.',
      'Black Rot ho nhwehwɛmu ntɛm si kwan ma woantumi anhwere wo nnɔbae nyinaa.',
      'Afuo pa fiti ase firi AI nhwehwɛmu a wɔyɛ dabiara dabiara.',
    ] : [
      'Regular scanning helps in early disease detection.',
      'Early diagnosis can increase crop yield by up to 40%.',
      'Frequent field scouting prevents major disease outbreaks.',
      'Early detection means easier and cheaper treatment.',
      'Keep your cabbage healthy with weekly scans.',
      'Prompt action on first symptoms saves your harvest.',
      'Proactive monitoring is key to high quality produce.',
      'Detecting Black Rot early prevents total field loss.',
      'A healthy field starts with regular AI leaf checks.',
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        height: 200,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _assetImages.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Image.asset(_assetImages[index], fit: BoxFit.cover),
            ),
            
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          provider.tr('CROP CARE TIP'),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      tips[_currentPage % tips.length],
                      key: ValueKey<int>(_currentPage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            Positioned(
              top: 16,
              right: 20,
              child: Row(
                children: List.generate(
                  _assetImages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(left: 4),
                    height: 4,
                    width: _currentPage == index ? 16 : 4,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
