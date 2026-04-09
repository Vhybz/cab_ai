import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/prediction_model.dart';
import 'tflite_service.dart';

class AppProvider with ChangeNotifier {
  final TFLiteService _tfLiteService = TFLiteService();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  
  File? _selectedImage;
  Prediction? _currentPrediction;
  bool _isLoading = false;
  List<Prediction> _history = [];
  
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'English';
  String _userName = 'Guest';
  String _locationName = 'Kumasi';
  double _lat = 6.6666;
  double _lon = -1.6163;

  File? get selectedImage => _selectedImage;
  Prediction? get currentPrediction => _currentPrediction;
  bool get isLoading => _isLoading;
  List<Prediction> get history => _history;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get userName => _userName;
  String get locationName => _locationName;
  double get lat => _lat;
  double get lon => _lon;

  AppProvider() {
    _loadData();
    _tfLiteService.loadModel();
    _initTts();
  }

  Future<void> _loadData() async {
    final settingsBox = Hive.box('settings');
    _userName = settingsBox.get('userName', defaultValue: 'Guest');
    _language = settingsBox.get('language', defaultValue: 'English');
    _themeMode = settingsBox.get('isDarkMode', defaultValue: false) ? ThemeMode.dark : ThemeMode.light;
    _locationName = settingsBox.get('locationName', defaultValue: 'Kumasi');
    _lat = settingsBox.get('lat', defaultValue: 6.6666);
    _lon = settingsBox.get('lon', defaultValue: -1.6163);

    final historyBox = Hive.box('scan_history');
    final List<dynamic> historyData = historyBox.get('history', defaultValue: []);
    _history = historyData.map((e) => Prediction.fromMap(Map<String, dynamic>.from(e))).toList();
    
    notifyListeners();
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    Hive.box('settings').put('isDarkMode', isDarkMode);
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    Hive.box('settings').put('language', lang);
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    Hive.box('settings').put('userName', name);
    notifyListeners();
  }

  void setGuestUser() {
    setUserName('Guest');
  }

  void setLocation(double lat, double lon, String name) {
    _lat = lat;
    _lon = lon;
    _locationName = name;
    Hive.box('settings').put('lat', lat);
    Hive.box('settings').put('lon', lon);
    Hive.box('settings').put('locationName', name);
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition();
      _lat = position.latitude;
      _lon = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lon);
      if (placemarks.isNotEmpty) {
        _locationName = placemarks[0].locality ?? placemarks[0].administrativeArea ?? 'My Farm';
      }
      
      Hive.box('settings').put('lat', _lat);
      Hive.box('settings').put('lon', _lon);
      Hive.box('settings').put('locationName', _locationName);
      
      notifyListeners();
    } catch (e) {
      print('Location error: $e');
    }
  }

  String getSuggestedActivity(DateTime day) {
    if (_history.isNotEmpty) {
      String latestDisease = _history.first.diseaseName;
      if (latestDisease == 'Black Rot' && (day.weekday == DateTime.tuesday || day.weekday == DateTime.friday)) {
        return _language == 'Twi' ? 'Wuo Aduane ma Black Rot' : 'Copper Fungicide Spray';
      }
      if (latestDisease == 'Downy Mildew' && day.weekday == DateTime.monday) {
        return _language == 'Twi' ? 'Hwɛ nhaban no ase' : 'Check Leaf Undersides';
      }
    }

    if (day.weekday == DateTime.monday || day.weekday == DateTime.thursday) {
      return _language == 'Twi' ? 'Gugu nsuo paa' : 'Deep Watering';
    } else if (day.weekday == DateTime.wednesday) {
      return _language == 'Twi' ? 'Fa AI hwehwɛ nhaban mu' : 'AI Leaf Scanning';
    } else if (day.weekday == DateTime.saturday) {
      return _language == 'Twi' ? 'Popa afuo no mu' : 'Field Pruning & Clearing';
    } else if (day.day % 10 == 0) {
      return _language == 'Twi' ? 'Fa duane gu mu' : 'Fertilizer Application';
    }
    return _language == 'Twi' ? 'Hwɛ afuo no mu' : 'General Field Scouting';
  }

  final Map<String, Map<String, String>> _diseaseData = {
    'Black Rot': {
      'description': 'A serious bacterial disease causing V-shaped yellow lesions on leaf margins.',
      'treatment': 'Use disease-free seeds, rotate crops, and apply copper-based fungicides.',
      'twi_name': 'Black Rot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa bi a ɛma nhaban no ano yɛ akokoɔsradeɛ na ɛporɔ.',
      'twi_treatment': 'Fa aba a ho tɛ, sesa nnɔbae no, na fa nnuru a kɔperea wom gu so.'
    },
    'Downy Mildew': {
      'description': 'A fungal disease appearing as yellow spots on top of leaves and white mold underneath.',
      'treatment': 'Improve air circulation, avoid overhead watering, and use appropriate fungicides.',
      'twi_name': 'Downy Mildew Yadeɛ',
      'twi_description': 'Yadeɛ yi ma nhaban no so yɛ nsuwa-nsuwa akokoɔsradeɛ na ase yɛ mfutuo fitaa.',
      'twi_treatment': 'Ma mframa mbɔ mu yiye, mma nsuo nka nhaban no so pii, na fa nnuru a ɛfata gu so.'
    },
    'White Rust': {
      'description': 'Characterized by white, chalky pustules on the underside of leaves.',
      'treatment': 'Remove infected plants, rotate crops, and use resistant varieties if available.',
      'twi_name': 'White Rust Yadeɛ',
      'twi_description': 'Yadeɛ yi ma nhaban no ase yɛ mfufuo te sɛ kyɛke.',
      'twi_treatment': 'Tu nhaban a ayɛ yadeɛ no gu, sesa nnɔbae no, na fa aba a ɛmpirɛ yadeɛ yi.'
    },
    'Healthy': {
      'description': 'The cabbage leaf appears healthy with no visible signs of disease.',
      'treatment': 'Continue regular monitoring and maintain good agricultural practices.',
      'twi_name': 'Nhyehyɛe Pa',
      'twi_description': 'Kabeji nhaban yi ho yɛ, yadeɛ biara nni ho.',
      'twi_treatment': 'Kɔ so hwɛ wo nnɔbae no so yiye na kɔ so yɛ adwuma pa.'
    },
  };

  Future<void> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    
    if (pickedFile != null) {
      // Save image to permanent storage
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
      
      _selectedImage = savedImage;
      _currentPrediction = null;
      _isLoading = true;
      notifyListeners();

      try {
        final result = await _tfLiteService.classifyImage(pickedFile.path);
        
        if (result != null) {
          String label = result['label'];
          double confidence = result['confidence'];
          
          final data = _diseaseData[label];
          
          _currentPrediction = Prediction(
            diseaseName: _language == 'Twi' ? (data?['twi_name'] ?? label) : label,
            confidence: confidence,
            description: _language == 'Twi' ? (data?['twi_description'] ?? 'Ankyerɛmu biara nni hɔ') : (data?['description'] ?? 'Unknown'),
            treatment: _language == 'Twi' ? (data?['twi_treatment'] ?? 'Ayaresa biara nni hɔ') : (data?['treatment'] ?? 'No treatment info available.'),
            imagePath: savedImage.path,
            dateTime: DateTime.now(),
          );
          
          _history.insert(0, _currentPrediction!);
          _saveHistory();
        }
      } catch (e) {
        print('Error during classification: $e');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void setCurrentPrediction(Prediction prediction) {
    _currentPrediction = prediction;
    notifyListeners();
  }

  void deleteScan(Prediction prediction) {
    _history.removeWhere((item) => item.dateTime == prediction.dateTime && item.imagePath == prediction.imagePath);
    
    try {
      final file = File(prediction.imagePath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
    
    _saveHistory();
    notifyListeners();
  }

  void _saveHistory() {
    final historyBox = Hive.box('scan_history');
    final historyData = _history.map((e) => e.toMap()).toList();
    historyBox.put('history', historyData);
  }

  @override
  void dispose() {
    _tfLiteService.dispose();
    super.dispose();
  }
}
