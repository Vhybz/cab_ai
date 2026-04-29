import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';
import 'result_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'chatbot_screen.dart';
import 'schedule_screen.dart';
import 'weather_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleScan(BuildContext context, ImageSource source) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.pickImage(source, context);
    if (context.mounted && provider.currentPrediction != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF4F7F4),
      drawer: _buildRefinedDrawer(context),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding > 0 ? 0 : 10),
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ChatbotScreen())),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          icon: const Icon(Icons.forum_rounded),
          label: const Text('Farm AI', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return SafeArea(
            top: false, // Allow SliverAppBar to go under status bar
            child: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 140.0,
                      floating: true,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: isDark 
                          ? theme.scaffoldBackgroundColor.withOpacity(0.9) 
                          : Colors.white.withOpacity(0.9),
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: false,
                        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
                        title: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              provider.tr('HOME'),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, MMMM dd').format(DateTime.now()),
                              style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        background: Container(color: Colors.transparent),
                      ),
                      leading: Builder(
                        builder: (context) => IconButton(
                          icon: Icon(Icons.menu_open_rounded, color: colorScheme.primary, size: 28),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: colorScheme.primary.withOpacity(0.1),
                              backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
                              child: provider.avatarUrl == null ? Icon(Icons.person, color: colorScheme.primary) : null,
                            ),
                          ),
                        ),
                      ],
                    ),
          
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenSize.width > 600 ? 40 : 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            _buildWelcomeSection(provider, theme, colorScheme),
                            const SizedBox(height: 24),
                            const LeafSlideshow(),
                            const SizedBox(height: 24),
          
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeatherScreen())),
                                    child: _buildSensorMetric(context, Icons.thermostat_rounded, '${provider.temp.toInt()}°C', provider.tr('Sunny'), Colors.orange),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsScreen())),
                                    child: _buildSensorMetric(context, Icons.analytics_rounded, provider.history.length.toString(), provider.tr('Scans'), Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
          
                            _buildDynamicScheduleCard(context, provider),
                            const SizedBox(height: 32),
          
                            Text(provider.tr('Diagnosis Tools'), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(child: _buildActionCard(context, provider.tr('Camera'), 'Scan Leaf', Icons.camera_alt_rounded, const Color(0xFF2E7D32), () => _handleScan(context, ImageSource.camera))),
                                const SizedBox(width: 12),
                                Expanded(child: _buildActionCard(context, provider.tr('Gallery'), 'Upload Image', Icons.photo_library_rounded, const Color(0xFF1B5E20), () => _handleScan(context, ImageSource.gallery))),
                              ],
                            ),
          
                            const SizedBox(height: 32),
          
                            if (provider.history.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(provider.tr('Recent Scans'), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  TextButton(
                                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen())),
                                    child: Row(
                                      children: [
                                        Text(provider.tr('View all'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const Icon(Icons.chevron_right_rounded, size: 20),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildModernHistoryList(context, provider),
                            ],
                            // Dynamic bottom spacing that respects the system navigation bar and FAB
                            SizedBox(height: bottomPadding + 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (provider.isLoading) _buildAnalysisOverlay(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(AppProvider provider, ThemeData theme, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${provider.timeBasedGreeting},',
                style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              Text(
                '${provider.firstName}! 👋',
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface),
              ),
            ],
          ),
        ),
        _buildStatusChip(provider),
      ],
    );
  }

  Widget _buildStatusChip(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            provider.isGuest ? 'GUEST' : 'ACTIVE',
            style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorMetric(BuildContext context, IconData icon, String value, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHistoryList(BuildContext context, AppProvider provider) {
    final history = provider.history;
    final displayCount = history.length > 3 ? 3 : history.length;

    return Column(
      children: List.generate(displayCount, (index) {
        final scan = history[index];
        final isHealthy = scan.diseaseName.toLowerCase().contains('healthy') || scan.diseaseName.contains('Nhyehy');
        final statusColor = isHealthy ? Colors.green : (scan.diseaseName.contains('Not a') ? Colors.redAccent : Colors.orange);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: InkWell(
            onTap: () {
              provider.setCurrentPrediction(scan);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
            },
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Hero(
                    tag: scan.imagePath,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(width: 65, height: 65, child: _buildImage(scan)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan.diseaseName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM dd, hh:mm a').format(scan.dateTime),
                          style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${(scan.confidence * 100).toInt()}%',
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildImage(Prediction scan) {
    if (scan.isAsset) return Image.asset(scan.imagePath, fit: BoxFit.cover);
    if (scan.isNetwork || scan.imagePath.startsWith('http')) {
      return Image.network(scan.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    final file = File(scan.imagePath);
    return file.existsSync() ? Image.file(file, fit: BoxFit.cover) : const Icon(Icons.image_not_supported);
  }

  Widget _buildAnalysisOverlay(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 6, strokeCap: StrokeCap.round),
              const SizedBox(height: 32),
              Text(
                provider.tr(provider.analysisMessage),
                style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(provider.tr('Our AI is detecting diseases'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorScheme.primary.withOpacity(0.05), colorScheme.primary.withOpacity(0.15)]),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(provider.tr('Daily Recommendation'), style: TextStyle(fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: -0.5)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen())),
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(16)),
                child: Icon(
                  suggestion.contains('Water') || suggestion.contains('Nsuo') ? Icons.water_drop_rounded : 
                  suggestion.contains('Scan') ? Icons.qr_code_scanner_rounded : 
                  Icons.agriculture_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(suggestion, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    Text(provider.tr('Based on crop cycle'), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefinedDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topRight: Radius.circular(30), bottomRight: Radius.circular(30))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark ? [const Color(0xFF1B2E1C), const Color(0xFF0A0A0A)] : [const Color(0xFF1B2E1C), const Color(0xFF2E7D32)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white24),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white12,
                        backgroundImage: provider.avatarUrl != null ? NetworkImage(provider.avatarUrl!) : null,
                        child: provider.avatarUrl == null ? const Icon(Icons.person, color: Colors.white, size: 35) : null,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  provider.userName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      provider.isGuest ? 'Standard Access' : 'Pro Farmer Account',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                _drawerTile(context, Icons.dashboard_rounded, provider.tr('Home'), null, true),
                _drawerTile(context, Icons.cloud_rounded, provider.tr('Weather'), const WeatherScreen(), false),
                _drawerTile(context, Icons.event_note_rounded, provider.tr('Schedule'), const ScheduleScreen(), false),
                _drawerTile(context, Icons.insights_rounded, provider.tr('Analytics'), const AnalyticsScreen(), false),
                _drawerTile(context, Icons.history_edu_rounded, provider.tr('History'), const HistoryScreen(), false),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                  child: Divider(color: Colors.grey, thickness: 0.2),
                ),
                
                Text(
                  '   ${provider.tr('Settings').toUpperCase()}',
                  style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                _drawerTile(context, Icons.settings_rounded, provider.tr('Settings'), const SettingsScreen(), false),
                _drawerTile(context, Icons.info_rounded, provider.tr('About Doctor'), const AboutScreen(), false),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () async {
                await provider.signOut();
                if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      provider.tr('Logout'),
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Text(
            'Version 1.0.1 (Stable)',
            style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _drawerTile(BuildContext context, IconData icon, String label, Widget? target, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: () {
          Navigator.pop(context);
          if (target != null) Navigator.push(context, MaterialPageRoute(builder: (context) => target));
        },
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : (isDark ? Colors.white60 : Colors.black54),
          size: 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: isSelected 
          ? Container(width: 4, height: 20, decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(10)))
          : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
  final List<String> _assetImages = ['assets/images/c1.jpg', 'assets/images/c2.jpg', 'assets/images/c3.jpg', 'assets/images/c4.jpg', 'assets/images/c5.jpg', 'assets/images/c6.jpg', 'assets/images/c7.jpg', 'assets/images/c8.jpg', 'assets/images/c9.jpg'];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_currentPage < _assetImages.length - 1) _currentPage++; else _currentPage = 0;
      if (_pageController.hasClients) _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutQuint);
    });
  }

  @override
  void dispose() { _timer?.cancel(); _pageController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<AppProvider>(context);
    final List<String> tips = provider.language == 'Twi' ? ['Bere nyinaa scan nhaban no sɛnea ɛbɛyɛ a wobɛhu yadeɛ ntɛm.', 'Yadeɛ ho nhwehwɛmu ntɛm tumi ma nnɔbae pii si so bɛyɛ 40%.', 'Bere nyinaa kɔ afuo mu hwɛ nnɔbae no sɛnea ɛbɛyɛ a yadeɛ biara remma.'] : ['Regular scanning helps in early disease detection.', 'Early diagnosis can increase crop yield by up to 40%.', 'Frequent field scouting prevents major outbreaks.'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            PageView.builder(controller: _pageController, itemCount: _assetImages.length, onPageChanged: (index) => setState(() => _currentPage = index), itemBuilder: (context, index) => Image.asset(_assetImages[index], fit: BoxFit.cover)),
            Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black87, Colors.transparent])))),
            Positioned(
              bottom: 24, left: 24, right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: Text(provider.tr('CROP CARE TIP'), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  Text(tips[_currentPage % tips.length], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.2)),
                ],
              ),
            ),
            Positioned(top: 20, right: 24, child: Row(children: List.generate(_assetImages.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 300), margin: const EdgeInsets.only(left: 4), height: 4, width: _currentPage == index ? 20 : 4, decoration: BoxDecoration(color: _currentPage == index ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(2)))))),
          ],
        ),
      ),
    );
  }
}
