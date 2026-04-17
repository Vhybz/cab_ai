import 'tflite_service_interface.dart';

class TFLiteService implements TFLiteServiceInterface {
  @override
  Future<void> loadModel() async {
    print('TFLite Model loading skipped on Web');
  }

  @override
  Future<Map<String, dynamic>?> classifyImage(String imagePath) async {
    // Return a mock result for web testing
    await Future.delayed(const Duration(seconds: 1));
    return {
      'label': 'Healthy',
      'confidence': 1.0,
      'isLeaf': true,
    };
  }

  @override
  void dispose() {
    print('TFLite Service disposed on Web');
  }
}
