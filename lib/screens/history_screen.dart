import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isSelectionMode = false;
  final Set<Prediction> _selectedItems = {};

  void _toggleSelection(Prediction item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
        if (_selectedItems.isEmpty) _isSelectionMode = false;
      } else {
        _selectedItems.add(item);
        _isSelectionMode = true;
      }
    });
  }

  void _selectAll(List<Prediction> history) {
    setState(() {
      if (_selectedItems.length == history.length) {
        _selectedItems.clear();
        _isSelectionMode = false;
      } else {
        _selectedItems.clear();
        _selectedItems.addAll(history);
        _isSelectionMode = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final history = provider.history;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, provider, history, colorScheme, isDark),
          if (history.isEmpty)
            _buildEmptyState(provider, colorScheme)
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = history[index];
                    final isSelected = _selectedItems.contains(item);
                    return _buildHistoryItem(context, provider, item, isSelected, isDark, colorScheme);
                  },
                  childCount: history.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode ? FloatingActionButton.extended(
        onPressed: () => _deleteSelected(provider),
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
        label: Text(provider.tr('DELETE'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppProvider provider, List<Prediction> history, ColorScheme colorScheme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: _isSelectionMode ? Colors.redAccent : colorScheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () {
          if (_isSelectionMode) {
            setState(() { _isSelectionMode = false; _selectedItems.clear(); });
          } else {
            Navigator.pop(context);
          }
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          _isSelectionMode ? '${_selectedItems.length} ${provider.tr('Selected')}' : provider.tr('Scan History'),
          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18, letterSpacing: -0.5),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isSelectionMode 
                ? [Colors.redAccent, Colors.red.shade900]
                : [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  _isSelectionMode ? Icons.delete_forever_rounded : Icons.history_edu_rounded, 
                  size: 150, 
                  color: Colors.white.withOpacity(0.1)
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (history.isNotEmpty) ...[
          if (_isSelectionMode)
            IconButton(
              icon: Icon(_selectedItems.length == history.length ? Icons.deselect : Icons.select_all, color: Colors.white),
              onPressed: () => _selectAll(history),
            )
          else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                if (value == 'select') setState(() => _isSelectionMode = true);
                else if (value == 'delete_all') _deleteAll(provider);
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'select', child: Text(provider.tr('Select Scans'))),
                PopupMenuItem(value: 'delete_all', child: Text(provider.tr('Delete All'), style: const TextStyle(color: Colors.redAccent))),
              ],
            ),
        ]
      ],
    );
  }

  Widget _buildEmptyState(AppProvider provider, ColorScheme colorScheme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(provider.tr('No history yet.'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, AppProvider provider, Prediction item, bool isSelected, bool isDark, ColorScheme colorScheme) {
    final isHealthy = item.diseaseName.toLowerCase().contains('healthy') || item.diseaseName.contains('Nhyehy');
    final statusColor = isHealthy ? Colors.green : (item.diseaseName.contains('Not a') ? Colors.redAccent : Colors.orange);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? colorScheme.primary : Colors.grey.withOpacity(0.1), width: 2),
        boxShadow: [if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        onLongPress: () => _toggleSelection(item),
        onTap: () {
          if (_isSelectionMode) _toggleSelection(item);
          else {
            provider.setCurrentPrediction(item);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResultScreen()));
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_isSelectionMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (val) => _toggleSelection(item),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(width: 8),
              ],
              Hero(
                tag: item.imagePath,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(width: 70, height: 70, child: _buildImage(item)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.diseaseName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(DateFormat('MMM dd, yyyy • hh:mm a').format(item.dateTime), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${(item.confidence * 100).toInt()}%', style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _deleteSelected(AppProvider provider) async {
    provider.deleteMultipleScans(_selectedItems.toList());
    setState(() { _selectedItems.clear(); _isSelectionMode = false; });
  }

  Future<void> _deleteAll(AppProvider provider) async {
    provider.deleteAllHistory();
    setState(() { _selectedItems.clear(); _isSelectionMode = false; });
  }
}
