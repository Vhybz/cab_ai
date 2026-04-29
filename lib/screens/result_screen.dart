import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import '../services/app_provider.dart';
import '../models/prediction_model.dart';

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
    String text = 'Cabbage Doctor Report\n\nDisease: $disease\n\nRecommended Treatment: $treatment';
    if (isAsset) {
      Share.share(text, subject: 'Cabbage Health Report');
    } else {
      Share.shareXFiles([XFile(imagePath)], text: text, subject: 'Cabbage Health Report');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final prediction = provider.currentPrediction;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isTwi = provider.language == 'Twi';
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    if (prediction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: const Center(child: Text('No prediction found.')),
      );
    }

    final isNotLeaf = !prediction.isLeaf;
    final isHealthy = prediction.diseaseName.toLowerCase().contains('healthy') || 
                      prediction.diseaseName.toLowerCase().contains('nhyehyɛe');

    Color statusColor = isNotLeaf ? Colors.redAccent : (isHealthy ? Colors.green : Colors.orange);
    IconData statusIcon = isNotLeaf ? Icons.error_outline_rounded : (isHealthy ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: screenSize.height * 0.45,
            pinned: true,
            stretch: true,
            backgroundColor: statusColor,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: prediction.imagePath, child: _buildImage(prediction)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
                    onPressed: () => _shareReport(
                      prediction.diseaseName, 
                      prediction.treatment, 
                      prediction.imagePath,
                      prediction.isAsset,
                      prediction.isNetwork,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 24, vertical: 32),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isNotLeaf ? (isTwi ? 'MFOMSOƆ' : 'ERROR') : (isHealthy ? (isTwi ? 'PA' : 'HEALTHY') : (isTwi ? 'YADEƐ' : 'DETECTED')),
                                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                prediction.diseaseName,
                                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: colorScheme.onSurface),
                              ),
                            ],
                          ),
                        ),
                        if (!isNotLeaf) _buildConfidenceCircle(prediction.confidence, statusColor),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    _buildVoiceActionCard(provider, prediction, isTwi, colorScheme),
                    const SizedBox(height: 32),
                    
                    Text(isTwi ? 'FA FA HO' : 'DETAILED ANALYSIS', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                    const SizedBox(height: 16),
                    
                    _buildInfoSection(context, Icons.description_rounded, isTwi ? 'NkyerƐmu' : 'Diagnosis', prediction.description, colorScheme.primary),
                    const SizedBox(height: 16),
                    if (!isNotLeaf)
                      _buildInfoSection(context, Icons.medication_rounded, isTwi ? 'Ayaresa' : 'Treatment Plan', prediction.treatment, statusColor),
                    
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 5,
                        shadowColor: colorScheme.primary.withOpacity(0.4),
                      ),
                      child: Text(isTwi ? 'KƆ FIE' : 'RETURN TO HOME', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCircle(double confidence, Color color) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2), width: 2)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(value: confidence, strokeWidth: 6, backgroundColor: color.withOpacity(0.1), color: color, strokeCap: StrokeCap.round),
          ),
          Text('${(confidence * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        ],
      ),
    );
  }

  Widget _buildVoiceActionCard(AppProvider provider, Prediction prediction, bool isTwi, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => _speak('${prediction.diseaseName}. ${prediction.description}. ${isTwi ? 'Ayaresa ne sɛ' : 'Treatment'}: ${prediction.treatment}', provider.language),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(_isSpeaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded, color: Colors.white, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isTwi ? 'Tie Ayaresa no' : 'Listen to Advice', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(isTwi ? 'Pia ha na tie afutuo' : 'Tap to hear AI voice guidance', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, IconData icon, String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(fontSize: 15, height: 1.6, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  Widget _buildImage(Prediction scan) {
    if (scan.isAsset) return Image.asset(scan.imagePath, fit: BoxFit.cover);
    if (scan.isNetwork || scan.imagePath.startsWith('http')) {
      return Image.network(scan.imagePath, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey, child: const Icon(Icons.broken_image)));
    }
    final file = File(scan.imagePath);
    return file.existsSync() ? Image.file(file, fit: BoxFit.cover) : Container(color: Colors.grey, child: const Icon(Icons.image_not_supported));
  }
}
