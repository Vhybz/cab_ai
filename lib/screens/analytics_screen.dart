import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/app_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<AppProvider>(context).history;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Logic to count diseases
    Map<String, int> counts = {};
    for (var item in history) {
      counts[item.diseaseName] = (counts[item.diseaseName] ?? 0) + 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: history.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 80, color: colorScheme.outlineVariant),
                    const SizedBox(height: 16),
                    Text('No data available for analytics yet.', style: TextStyle(color: colorScheme.outline)),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Summary Cards
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard(context, 'Total Scans', history.length.toString(), Icons.qr_code_scanner_rounded, colorScheme.primary)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildSummaryCard(context, 'Healthy Leaves', (counts['Healthy'] ?? 0).toString(), Icons.check_circle_rounded, Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Pie Chart
                  Text('Disease Distribution', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    height: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: PieChart(
                      PieChartData(
                        sections: counts.entries.map((e) {
                          final isHealthy = e.key == 'Healthy';
                          return PieChartSectionData(
                            color: isHealthy ? Colors.green : _getDiseaseColor(e.key),
                            value: e.value.toDouble(),
                            title: '${(e.value / history.length * 100).toInt()}%',
                            radius: 50,
                            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }).toList(),
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 3. AI Insights & Suggested Next Steps
                  Text('AI Recommended Actions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildAIActions(context, counts),
                  
                  const SizedBox(height: 32),

                  // 4. Detailed Breakdown
                  Text('Detailed Breakdown', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...counts.entries.map((e) => _buildStatRow(context, e.key, e.value, history.length)),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Color _getDiseaseColor(String name) {
    switch (name) {
      case 'Black Rot': return Colors.brown;
      case 'Downy Mildew': return Colors.orange;
      case 'White Rust': return Colors.blueGrey;
      default: return Colors.redAccent;
    }
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value, 
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: color),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title, 
            style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAIActions(BuildContext context, Map<String, int> counts) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Sort diseases by frequency (excluding Healthy)
    var diseases = counts.entries
        .where((e) => e.key != 'Healthy')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (diseases.isEmpty) {
      return _buildActionItem(
        context,
        Icons.verified_rounded,
        Colors.green,
        'Excellent field health!',
        'Continue your weekly AI scans to ensure your crop stays disease-free.',
      );
    }

    String topDisease = diseases.first.key;
    
    return Column(
      children: [
        if (topDisease == 'Black Rot')
          _buildActionItem(
            context,
            Icons.warning_amber_rounded,
            Colors.orange,
            'Manage Black Rot Spread',
            'Based on your data, we suggest clearing all cabbage debris and ensuring good drainage immediately.',
          ),
        if (topDisease == 'Downy Mildew')
          _buildActionItem(
            context,
            Icons.water_drop_rounded,
            Colors.blue,
            'Control Humidity',
            'Avoid overhead irrigation. Switch to morning watering to allow leaves to dry before night.',
          ),
        if (topDisease == 'White Rust')
          _buildActionItem(
            context,
            Icons.content_cut_rounded,
            Colors.redAccent,
            'Urgent Pruning',
            'Remove and safely dispose of leaves showing white pustules to protect healthy plants.',
          ),
        const SizedBox(height: 12),
        _buildActionItem(
          context,
          Icons.calendar_month_rounded,
          colorScheme.primary,
          'Schedule Expert Scouting',
          'Use the Scan Schedule to set a full-field inspection for tomorrow morning.',
        ),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, Color color, String title, String desc) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  desc, 
                  style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String name, int count, int total) {
    final theme = Theme.of(context);
    double percent = count / total;
    Color color = name == 'Healthy' ? Colors.green : _getDiseaseColor(name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 8),
              Text('$count (${(percent * 100).toStringAsFixed(1)}%)', style: TextStyle(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}
