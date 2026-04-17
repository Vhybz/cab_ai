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

  Future<void> _deleteSelected(AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.tr('Delete Selected?')),
        content: Text(provider.tr('This action cannot be undone.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(provider.tr('CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(provider.tr('DELETE')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteMultipleScans(_selectedItems.toList());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.tr('Selected Scans Deleted'))),
      );
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }
  }

  Future<void> _deleteAll(AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(provider.tr('Delete All History?')),
        content: Text(provider.tr('Are you sure you want to delete all scans?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(provider.tr('CANCEL')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(provider.tr('DELETE')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      provider.deleteAllHistory();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.tr('ALL SCANS DELETED'))),
      );
      setState(() {
        _selectedItems.clear();
        _isSelectionMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final history = provider.history;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode 
            ? '${_selectedItems.length} ${provider.tr('Selected')}' 
            : provider.tr('Detection History')),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
        leading: _isSelectionMode 
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedItems.clear();
                }),
              )
            : null,
        actions: [
          if (history.isNotEmpty) ...[
            if (_isSelectionMode) ...[
              IconButton(
                icon: Icon(_selectedItems.length == history.length 
                    ? Icons.deselect 
                    : Icons.select_all),
                onPressed: () => _selectAll(history),
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
                onPressed: () => _deleteSelected(provider),
              ),
            ] else ...[
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'select') {
                    setState(() => _isSelectionMode = true);
                  } else if (value == 'delete_all') {
                    _deleteAll(provider);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'select',
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outlined, size: 20),
                        const SizedBox(width: 12),
                        Text(provider.tr('Select Scans')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Text(provider.tr('Delete All'), style: const TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ]
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    provider.tr('No history yet.\nStart by scanning a leaf!'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final isSelected = _selectedItems.contains(item);

                return InkWell(
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      _toggleSelection(item);
                    }
                  },
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(item);
                    } else {
                      provider.setCurrentPrediction(item);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ResultScreen()),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).colorScheme.primary 
                            : Colors.grey.withOpacity(0.1)
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (_isSelectionMode) ...[
                            Checkbox(
                              value: isSelected,
                              onChanged: (val) => _toggleSelection(item),
                              shape: const CircleBorder(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Hero(
                            tag: item.imagePath,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImage(item),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.diseaseName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy • hh:mm a').format(item.dateTime),
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(item.confidence * 100).toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (!_isSelectionMode) ...[
                                const SizedBox(height: 4),
                                const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildImage(Prediction scan) {
    if (scan.isAsset) {
      return Image.asset(scan.imagePath, width: 60, height: 60, fit: BoxFit.cover);
    } else if (scan.isNetwork || scan.imagePath.startsWith('http')) {
      return Image.network(
        scan.imagePath, 
        width: 60, height: 60, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey, width: 60, height: 60, child: const Icon(Icons.broken_image)),
      );
    } else {
      return Image.file(File(scan.imagePath), width: 60, height: 60, fit: BoxFit.cover);
    }
  }
}
