import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'tflite_service_interface.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TFLiteService implements TFLiteServiceInterface {
  Interpreter? _interpreter;
  
  final List<String> _labels = [
    'Black Rot', 
    'Healthy', 
    'Downy Mildew', 
    'Alternaria Spot'
  ];

  @override
  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'assets/images/inception_model.tflite',
        options: options,
      );
      _interpreter!.allocateTensors();
    } catch (e) {
      print('TFLite Error (Load): $e');
    }
  }

  Future<String> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final documentDirectory = await getTemporaryDirectory();
      final file = File('${documentDirectory.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (e) {
      throw Exception('TFLite: Failed to download image: $e');
    }
  }

  /// Advanced Biological Heuristic for Cabbage Leaves
  Map<String, double> _getPlantMetrics(img.Image image) {
    int plantPixels = 0;
    int sampled = 0;
    double sumExG = 0;
    double sumGLI = 0;
    double sumSat = 0;
    double sumSat2 = 0;
    
    for (int y = 0; y < image.height; y += 4) {
      for (int x = 0; x < image.width; x += 4) {
        sampled++;
        final pixel = image.getPixel(x, y);
        
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        // 1. GLI (Green Leaf Index): (2G - R - B) / (2G + R + B)
        double denominator = (2 * g) + r + b;
        double gli = (denominator != 0) ? (2 * g - r - b) / denominator : 0;
        sumGLI += gli;

        // 2. ExG (Excess Green)
        double exg = (2.0 * g) - r - b;
        sumExG += exg;

        // 3. Saturation
        double maxC = max(r, max(g, b));
        double minC = min(r, min(g, b));
        double sat = (maxC == 0) ? 0 : (maxC - minC);
        sumSat += sat;
        sumSat2 += sat * sat;

        bool isGreenish = (g > r && g > b * 1.05);
        bool isYellowish = (r > b * 1.3 && g > b * 1.1 && (r - g).abs() < 40);

        if ((isGreenish || isYellowish) && g > 35 && sat > 12) {
          if (gli > 0.02 || exg > 5) {
            plantPixels++;
          }
        }
      }
    }
    
    double ratio = plantPixels / sampled;
    double avgExG = sumExG / sampled;
    double avgGLI = sumGLI / sampled;
    double avgSat = sumSat / sampled;
    double stdDevSat = sqrt(max(0, (sumSat2 / sampled) - (avgSat * avgSat)));
    
    return {
      'ratio': ratio, 
      'avgExG': avgExG,
      'avgGLI': avgGLI,
      'avgSat': avgSat,
      'stdDevSat': stdDevSat,
    };
  }

  @override
  Future<Map<String, dynamic>?> classifyImage(String imageSource) async {
    try {
      if (_interpreter == null) await loadModel();
      if (_interpreter == null) return null;

      String localPath = imageSource;
      if (imageSource.startsWith('http')) {
        localPath = await _downloadImage(imageSource);
      }

      final file = File(localPath);
      if (!file.existsSync()) return null;

      final bytes = file.readAsBytesSync();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      var metrics = _getPlantMetrics(originalImage);
      double ratio = metrics['ratio']!;
      double avgGLI = metrics['avgGLI']!;
      double avgSat = metrics['avgSat']!;
      double stdDevSat = metrics['stdDevSat']!;
      
      print('TFLite Metrics: Ratio=${(ratio * 100).toStringAsFixed(1)}%, GLI=${avgGLI.toStringAsFixed(2)}, SatVar=${stdDevSat.toStringAsFixed(1)}');

      final resizedImage = img.copyResize(originalImage, width: 224, height: 224);
      List<List<List<List<double>>>> input = [
        List.generate(224, (y) => 
          List.generate(224, (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          })
        )
      ];

      var output = List.generate(1, (i) => List.filled(_labels.length, 0.0));
      _interpreter!.run(input, output);

      List<double> probabilities = List<double>.from(output[0]);
      double maxScore = probabilities.reduce(max);
      int maxIndex = probabilities.indexOf(maxScore);
      
      print('TFLite Confidence: ${(maxScore * 100).toStringAsFixed(2)}% (${_labels[maxIndex]})');

      bool isLeaf = ratio > 0.38 && avgGLI > 0.03 && maxScore > 0.88;

      // Downy Mildew (Index 2) verification
      if (maxIndex == 2) {
         if (maxScore < 0.992 || avgGLI < 0.06 || ratio < 0.55 || stdDevSat < 10) {
           isLeaf = false;
           print('TFLite Reject: Downy Mildew failed validation.');
         }
      }

      // Alternaria Spot (Index 3) verification
      if (maxIndex == 3 && (maxScore < 0.96 || avgGLI < 0.04)) {
        isLeaf = false;
      }

      if (avgSat < 12 || stdDevSat < 5) {
        isLeaf = false;
        print('TFLite Reject: Monochromatic image.');
      }

      if (!isLeaf && maxScore > 0.999 && ratio > 0.25 && avgGLI > 0.02) {
        isLeaf = true;
      }

      return {
        'label': _labels[maxIndex],
        'confidence': maxScore,
        'index': maxIndex,
        'isLeaf': isLeaf, 
        'all_scores': probabilities,
      };
    } catch (e) {
      print('TFLite Inference Error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}
