import 'dart:math';

class TFLiteService {
  final List<String> _labels = ['Black Rot', 'Downy Mildew', 'White Rust', 'Healthy'];

  // Mock loading - does nothing for now
  Future<void> loadModel() async {
    print('TFLite Model loading skipped (Frontend Only Mode)');
    return;
  }

  // Mock inference for frontend testing
  Future<Map<String, dynamic>?> classifyImage(String imagePath) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    // Return a random prediction for demonstration
    final random = Random();
    int index = random.nextInt(_labels.length);
    double confidence = 0.7 + (random.nextDouble() * 0.25); // 70% to 95%

    return {
      'label': _labels[index],
      'confidence': confidence,
    };
  }

  void dispose() {}
}
