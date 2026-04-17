import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
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
import 'login_screen.dart';

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
        elevation: 6,
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
                    expandedHeight: 100.0,
                    floating: true,
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    backgroundColor: (isDark ? theme.scaffoldBackgroundColor : Colors.white).withOpacity(0.8),
                    surfaceTintColor: Colors.transparent,
                    leading: Builder(
                      builder: (context) => Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
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
                          icon: provider.avatarUrl != null 
                            ? Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: colorScheme.primary, width: 2),
                                  image: DecorationImage(
                                    image: NetworkImage(provider.avatarUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
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
                        provider.tr('CABBAGE DOCTOR'),
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 4,
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
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${provider.timeBasedGreeting},',
                                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey, fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      '${provider.firstName} 👋',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: colorScheme.onSurface,
                                        letterSpacing: -1,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircleAvatar(radius: 4, backgroundColor: Colors.green),
                                    const SizedBox(width: 8),
                                    Text(provider.tr('ACTIVE'), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const LeafSlideshow(),
                          const SizedBox(height: 28),

                          _buildSummaryRow(context, provider),
                          const SizedBox(height: 32),

                          Text(
                            provider.tr('Diagnosis Tools'),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionTile(
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
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionTile(
                                  context,
                                  provider.tr('Gallery'),
                                  Icons.photo_library_rounded,
                                  const Color(0xFF673AB7),
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

                          const SizedBox(height: 40),

                          if (provider.schedules.isNotEmpty) ...[
                            _buildSectionHeader(context, provider, 'Upcoming Schedule', const ScheduleScreen()),
                            const SizedBox(height: 12),
                            _buildUpcomingSchedulesList(context, provider),
                            const SizedBox(height: 32),
                          ],

                          if (provider.history.isNotEmpty) ...[
                            _buildSectionHeader(context, provider, 'Recent Activity', const HistoryScreen()),
                            const SizedBox(height: 12),
                            _buildCompactHistory(context, provider),
                            const SizedBox(height: 32),
                            
                            // Scan Analytics Graph
                            Text(
                              provider.tr('Scan Analytics'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 16),
                            _buildScanAnalyticsGraph(context, provider),
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

  Widget _buildScanAnalyticsGraph(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Map<int, int> dailyCounts = {};
    final now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final count = provider.history.where((s) => 
        s.dateTime.year == date.year && 
        s.dateTime.month == date.month && 
        s.dateTime.day == date.day
      ).length;
      dailyCounts[i] = count;
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 24, 24, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (dailyCounts.values.isEmpty ? 5 : dailyCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 2),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = now.subtract(Duration(days: 6 - value.toInt()));
                  return Text(DateFormat('E').format(date).substring(0, 1), style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold));
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (i) {
            final count = dailyCounts[6 - i] ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: count > 0 ? colorScheme.primary : Colors.grey.withOpacity(0.2),
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, AppProvider provider, String title, Widget target) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          provider.tr(title), 
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => target)),
          child: Text(provider.tr('See All')),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, AppProvider provider) {
    final colorScheme = Theme.of(context).colorScheme;
    final upcomingTask = provider.schedules.where((s) => s.dateTime.isAfter(DateTime.now())).firstOrNull;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            context,
            Icons.analytics_rounded,
            provider.history.length.toString(),
            provider.tr('Total Scans'),
            colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            context,
            Icons.event_available_rounded,
            upcomingTask != null ? DateFormat('MMM dd').format(upcomingTask.dateTime) : 'None',
            provider.tr('Next Task'),
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildUpcomingSchedulesList(BuildContext context, AppProvider provider) {
    final upcoming = provider.schedules
        .where((s) => s.dateTime.isAfter(DateTime.now()))
        .take(2)
        .toList();

    return Column(
      children: upcoming.map((item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_on_rounded, color: Colors.orange, size: 20),
          ),
          title: Text(provider.tr(item.activity), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(DateFormat('MMM dd, hh:mm a').format(item.dateTime), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ScheduleScreen())),
        ),
      )).toList(),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHistory(BuildContext context, AppProvider provider) {
    return Column(
      children: provider.history.take(3).map((scan) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        child: ListTile(
          onTap: () {
            provider.setCurrentPrediction(scan);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
          },
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildImage(scan),
          ),
          title: Text(scan.diseaseName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(DateFormat('MMM dd').format(scan.dateTime), style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
      )).toList(),
    );
  }

  Widget _buildImage(dynamic scan) {
    if (scan.isAsset) {
      return Image.asset(scan.imagePath, width: 48, height: 48, fit: BoxFit.cover);
    } else if (scan.isNetwork || scan.imagePath.startsWith('http')) {
      return Image.network(
        scan.imagePath, 
        width: 48, height: 48, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 48, height: 48, child: const Icon(Icons.broken_image, size: 20)),
      );
    } else {
      return Image.file(File(scan.imagePath), width: 48, height: 48, fit: BoxFit.cover);
    }
  }

  Widget _buildAnalysisOverlay(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: (isDark ? Colors.black : Colors.white).withOpacity(0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120, height: 120,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                      strokeWidth: 2,
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.green, highlightColor: Colors.greenAccent,
                    child: const Icon(Icons.eco_rounded, size: 60),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  provider.tr(provider.analysisMessage),
                  key: ValueKey<String>(provider.analysisMessage),
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text(provider.tr('Our AI is detecting diseases'), style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
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
          borderRadius: const BorderRadius.only(topRight: Radius.circular(40), bottomRight: Radius.circular(40)),
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
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 2)),
                      child: CircleAvatar(
                        radius: 40, 
                        backgroundColor: Colors.white10, 
                        backgroundImage: provider.avatarUrl != null 
                          ? NetworkImage(provider.avatarUrl!) 
                          : const AssetImage('assets/images/c10.jpg') as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(provider.firstName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text(provider.isGuest ? provider.tr('Standard Access') : provider.tr('Pro Farmer'), style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10, indent: 24, endIndent: 24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _drawerTile(context, Icons.dashboard_rounded, provider.tr('Home'), null, true),
                    _drawerTile(context, Icons.cloud_rounded, provider.tr('Weather'), const WeatherScreen(), false),
                    _drawerTile(context, Icons.event_note_rounded, provider.tr('Schedule'), const ScheduleScreen(), false),
                    _drawerTile(context, Icons.insights_rounded, provider.tr('Analytics'), const AnalyticsScreen(), false),
                    _drawerTile(context, Icons.history_edu_rounded, provider.tr('History'), const HistoryScreen(), false),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: Divider(color: Colors.white10)),
                    _drawerTile(context, Icons.settings_suggest_rounded, provider.tr('Settings'), const SettingsScreen(), false),
                    _drawerTile(context, Icons.contact_support_rounded, provider.tr('Help & About'), const AboutScreen(), false),
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(provider.tr('Logout'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      ],
                    ),
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
        leading: Icon(icon, color: isSelected ? Colors.greenAccent : Colors.white60, size: 22),
        title: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
      if (_pageController.hasClients) {
        setState(() {
          _currentPage = (_currentPage + 1) % _assetImages.length;
        });
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
      'Scan wo kabeji dabiara dabiara sɛnea ɛbƐyɛ a ɛho bɛyɛ den.',
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
                    colors: [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.2), Colors.transparent],
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
                    decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('CROP CARE TIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(tips[_currentPage % tips.length], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
