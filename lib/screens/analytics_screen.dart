import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  bool _isHealthy(Prediction scan) {
    final name = scan.diseaseName.toLowerCase();
    return name.contains('healthy') || name.contains('nhyehy');
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final history = provider.history;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final leafScans = history.where((s) => s.isLeaf).toList();
    Map<String, int> counts = {};
    int healthyCount = 0;
    for (var item in leafScans) {
      if (_isHealthy(item)) healthyCount++; else counts[item.diseaseName] = (counts[item.diseaseName] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, provider, colorScheme),
          SliverToBoxAdapter(
            child: history.isEmpty 
              ? _buildEmptyState(provider, colorScheme)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderStats(provider, healthyCount, colorScheme, isDark),
                      const SizedBox(height: 32),
                      _buildSectionLabel('DISEASE DISTRIBUTION'),
                      const SizedBox(height: 16),
                      _buildChartCard(leafScans, healthyCount, counts, isDark),
                      const SizedBox(height: 32),
                      _buildSectionLabel('AI INSIGHTS & ACTIONS'),
                      const SizedBox(height: 16),
                      _buildAIActions(context, provider, counts, healthyCount),
                      const SizedBox(height: 32),
                      _buildSectionLabel('DETAILED BREAKDOWN'),
                      const SizedBox(height: 16),
                      _buildBreakdownList(leafScans, healthyCount, counts, isDark, colorScheme),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          provider.tr('Field Analytics'), 
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5)
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(Icons.analytics_rounded, size: 150, color: Colors.white.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppProvider provider, ColorScheme colorScheme) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Icon(Icons.analytics_outlined, size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(provider.tr('No data available yet.'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(AppProvider provider, int healthy, ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        _statBox('Total Scans', provider.history.length.toString(), Icons.qr_code_scanner_rounded, colorScheme.primary, isDark),
        const SizedBox(width: 12),
        _statBox('Healthy', healthy.toString(), Icons.eco_rounded, Colors.green, isDark),
      ],
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 18)),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(List<Prediction> leafScans, int healthy, Map<String, int> counts, bool isDark) {
    if (leafScans.isEmpty) return const SizedBox();
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            if (healthy > 0) PieChartSectionData(color: Colors.green, value: healthy.toDouble(), title: '', radius: 25),
            ...counts.entries.map((e) => PieChartSectionData(color: _getColor(e.key), value: e.value.toDouble(), title: '', radius: 20)),
          ],
          centerSpaceRadius: 60,
          sectionsSpace: 4,
        ),
      ),
    );
  }

  Widget _buildAIActions(BuildContext context, AppProvider provider, Map<String, int> counts, int healthy) {
    final isTwi = provider.language == 'Twi';
    String title = healthy > 0 && counts.isEmpty ? (isTwi ? 'Afuom yɛ papa' : 'Field is Healthy') : (isTwi ? 'Yɛn adwumayɛ' : 'Immediate Action');
    String desc = healthy > 0 && counts.isEmpty ? (isTwi ? 'Kɔ so scan dabiara.' : 'Continue regular AI monitoring.') : (isTwi ? 'Hwɛ yadeɛ no so yiye.' : 'Follow the treatment plans for detected diseases.');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange.shade700]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(List<Prediction> leafScans, int healthy, Map<String, int> counts, bool isDark, ColorScheme colorScheme) {
    if (leafScans.isEmpty) return const SizedBox();
    return Column(
      children: [
        if (healthy > 0) _breakdownRow('Healthy', healthy, leafScans.length, Colors.green, isDark),
        ...counts.entries.map((e) => _breakdownRow(e.key, e.value, leafScans.length, _getColor(e.key), isDark)),
      ],
    );
  }

  Widget _breakdownRow(String name, int count, int total, Color color, bool isDark) {
    double progress = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('$count Scans', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: color.withOpacity(0.1), color: color),
          ),
        ],
      ),
    );
  }

  Color _getColor(String name) {
    if (name.contains('Black Rot')) return Colors.brown;
    if (name.contains('Downy')) return Colors.orange;
    return Colors.redAccent;
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }
}
