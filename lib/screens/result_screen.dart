import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_provider.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _speak(String text, String language) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      
      if (language == 'Twi') {
        await _flutterTts.setLanguage("ak-GH");
      } else {
        await _flutterTts.setLanguage("en-US");
      }
      
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(text);
      
      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  void _shareReport(String disease, String treatment, String imagePath, bool isAsset, bool isNetwork) {
    if (isAsset) {
      Share.share(
        'Cabbage Doctor Report\n\nDisease: $disease\n\nRecommended Treatment: $treatment',
        subject: 'Cabbage Health Report',
      );
    } else {
      // For network or local file images
      Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Cabbage Doctor Report\n\nDisease: $disease\n\nRecommended Treatment: $treatment',
        subject: 'Cabbage Health Report',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final prediction = provider.currentPrediction;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTwi = provider.language == 'Twi';

    if (prediction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No prediction found.')),
      );
    }

    final isNotLeaf = !prediction.isLeaf;
    final isHealthy = prediction.diseaseName.toLowerCase().contains('healthy') || 
                      prediction.diseaseName.toLowerCase().contains('nhyehyɛe');

    Color statusColor = isNotLeaf ? Colors.red : (isHealthy ? Colors.green : Colors.orange);
    IconData statusIcon = isNotLeaf ? Icons.error_outline_rounded : (isHealthy ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: statusColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: prediction.imagePath,
                child: _buildImage(prediction),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                onPressed: () => _shareReport(
                  prediction.diseaseName, 
                  prediction.treatment, 
                  prediction.imagePath,
                  prediction.isAsset,
                  prediction.isNetwork,
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner for logged-in users regarding cloud sync
                  if (!provider.isGuest)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isTwi ? 'Yɛahyehyɛ nhwehwɛmu yi asie wɔ cloud.' : 'Scan synced and secured in cloud.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 1. Status Indicator Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          isNotLeaf 
                            ? (isTwi ? 'ƐNYƐ NHABAN' : 'INVALID SPECIMEN') 
                            : (isHealthy ? (isTwi ? 'NHYEHYƐE PA' : 'HEALTHY CROP') : (isTwi ? 'YADEƐ WƆ HO' : 'DISEASE DETECTED')),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Diagnosis Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              prediction.diseaseName,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (!isNotLeaf) _buildConfidenceGauge(prediction.confidence, colorScheme, statusColor),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Voice Advice Button
                  InkWell(
                    onTap: () => _speak(
                      '${prediction.diseaseName}. ${prediction.description}. ${isTwi ? 'Sɛnea yɛsa yadeɛ yi ne sɛ' : 'Treatment'}: ${prediction.treatment}',
                      provider.language
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSpeaking ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              _isSpeaking 
                                ? (isTwi ? 'Gyae tie' : 'Stop Listening') 
                                : (isTwi ? 'Tie afutuo no wɔ Twi mu' : 'Listen to Advice'),
                              style: TextStyle(
                                color: colorScheme.primary, 
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 4. Detailed Condition Cards
                  _buildInfoCard(
                    context,
                    Icons.info_outline_rounded,
                    isTwi ? 'NkyerƐmu' : 'Description',
                    prediction.description,
                    colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  
                  if (!isNotLeaf)
                    _buildInfoCard(
                      context,
                      Icons.healing_rounded,
                      isTwi ? 'SƐnea yƐsa yadeƐ no' : 'Recommended Treatment',
                      prediction.treatment,
                      statusColor,
                    ),
                  
                  const SizedBox(height: 40),
                  
                  // 5. Action Buttons
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.dashboard_rounded),
                      label: Text(isTwi ? 'Kɔ Fie' : 'Back to Dashboard'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(dynamic scan) {
    if (scan.isAsset) {
      return Image.asset(scan.imagePath, fit: BoxFit.cover);
    } else if (scan.isNetwork || scan.imagePath.startsWith('http')) {
      return Image.network(
        scan.imagePath, 
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null));
        },
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900, child: const Center(child: Icon(Icons.broken_image, color: Colors.white24, size: 50))),
      );
    } else {
      return Image.file(File(scan.imagePath), fit: BoxFit.cover);
    }
  }

  Widget _buildConfidenceGauge(double confidence, ColorScheme colorScheme, Color statusColor) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: confidence,
            strokeWidth: 8,
            backgroundColor: statusColor.withOpacity(0.1),
            color: statusColor,
            strokeCap: StrokeCap.round,
          ),
        ),
        Text(
          '${(confidence * 100).toInt()}%',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.6)),
        ],
      ),
    );
  }
}
