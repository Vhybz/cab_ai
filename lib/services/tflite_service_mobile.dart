import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'tflite_service_interface.dart';

class TFLiteService implements TFLiteServiceInterface {
  Interpreter? _interpreter;
  
  // Refined labels based on latest feedback:
  // 0: Healthy, 1: Black Rot, 2: Downy Mildew (Matching user's training data)
  final List<String> _labels = ['Healthy', 'Black Rot', 'Downy Mildew'];
  
  final int _inputSize = 224; 

  @override
  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/images/cabbage_disease_classifier.tflite',
        options: options,
      );
      print('Model loaded with Input size: $_inputSize. Labels: $_labels');
    } catch (e) {
      print('TFLite Load Error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> classifyImage(String imagePath) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) {
      print('Interpreter is null after load attempt');
      return null;
    }

    try {
      final imageData = File(imagePath).readAsBytesSync();
      img.Image? originalImage = img.decodeImage(imageData);
      if (originalImage == null) return null;

      img.Image resizedImage = img.copyResize(
        originalImage,
        width: _inputSize,
        height: _inputSize,
      );

      var input = Float32List(1 * _inputSize * _inputSize * 3);
      int pixelIndex = 0;
      for (int y = 0; y < _inputSize; y++) {
        for (int x = 0; x < _inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input[pixelIndex++] = pixel.r / 255.0;
          input[pixelIndex++] = pixel.g / 255.0;
          input[pixelIndex++] = pixel.b / 255.0;
        }
      }

      var output = List.filled(1 * 3, 0.0).reshape([1, 3]);
      
      _interpreter!.run(
        input.buffer.asFloat32List().reshape([1, _inputSize, _inputSize, 3]), 
        output
      );

      List<double> scores = List<double>.from(output[0]);
      print('Raw Model Scores: $scores');
      
      double maxScore = scores.reduce(max);
      int maxIndex = scores.indexOf(maxScore);

      // Threshold logic: ensure it's actually identifying one of the classes
      double confidenceThreshold = 0.40;
      
      // If the model is extremely uncertain, it's not a cabbage leaf.
      bool isLeaf = maxScore >= confidenceThreshold;

      return {
        'label': isLeaf ? _labels[maxIndex] : 'Not a Cabbage Leaf',
        'confidence': maxScore,
        'isLeaf': isLeaf,
        'all_scores': scores,
      };
    } catch (e) {
      print('Inference Error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
  }
}
