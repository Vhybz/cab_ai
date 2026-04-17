import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'tflite_service_interface.dart';

class TFLiteService implements TFLiteServiceInterface {
  Interpreter? _interpreter;
  
  // Updated labels based on your model's newest metadata:
  // 0: white_rust, 1: downy_mildew, 2: black_rot
  final List<String> _labels = ['White Rust', 'Downy Mildew', 'Black Rot'];
  
  // Input size 64x64 as specified in your model metadata
  final int _inputSize = 64; 

  @override
  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      _interpreter = await Interpreter.fromAsset(
        'assets/images/cabbage_disease_classifier.tflite',
        options: options,
      );
      print('Model loaded. Input size: $_inputSize. Labels: $_labels');
    } catch (e) {
      print('TFLite Load Error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>?> classifyImage(String imagePath) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) return null;

    try {
      final imageData = File(imagePath).readAsBytesSync();
      img.Image? originalImage = img.decodeImage(imageData);
      if (originalImage == null) return null;

      // Resizing to 64x64 as required by your model
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
          // Normalizing to [0,1] as per usage instructions
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
      print('Model Prediction Scores: $scores');
      
      double maxScore = scores.reduce(max);
      int maxIndex = scores.indexOf(maxScore);

      // Threshold: Using 0.30 but keep the green-check to ensure we are looking at a leaf.
      double confidenceThreshold = 0.30;
      bool isLeaf = maxScore >= confidenceThreshold && _checkIfGreenish(resizedImage);

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

  bool _checkIfGreenish(img.Image image) {
    int greenPixels = 0;
    int totalPixels = image.width * image.height;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        if (pixel.g > pixel.r && pixel.g > pixel.b) greenPixels++;
      }
    }
    return (greenPixels / totalPixels) > 0.15;
  }

  @override
  void dispose() {
    _interpreter?.close();
  }
}
