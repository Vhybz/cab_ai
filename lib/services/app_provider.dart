import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/prediction_model.dart';
import '../models/schedule_model.dart';
import 'tflite_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class AppProvider with ChangeNotifier {
  final TFLiteService _tfLiteService = TFLiteService();
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  
  File? _selectedImage;
  Prediction? _currentPrediction;
  bool _isLoading = false;
  String _analysisMessage = 'ANALYZING LEAF...';
  List<Prediction> _history = [];
  List<Schedule> _schedules = [];
  
  ThemeMode _themeMode = ThemeMode.light;
  String _language = 'English';
  String _userName = 'Guest';
  String? _avatarUrl;
  String _locationName = 'Kumasi';
  double _lat = 6.6666;
  double _lon = -1.6163;
  bool _notificationsEnabled = true;

  // Weather properties
  double _temp = 28.0;
  String _weatherDesc = 'Sunny';
  bool _isWeatherLoading = false;

  // AI Chat properties
  bool _isChatLoading = false;

  File? get selectedImage => _selectedImage;
  Prediction? get currentPrediction => _currentPrediction;
  bool get isLoading => _isLoading;
  String get analysisMessage => _analysisMessage;
  List<Prediction> get history => _history;
  List<Schedule> get schedules => _schedules;
  ThemeMode get themeMode => _themeMode;
  String get language => _language;
  String get userName => _userName;
  String? get avatarUrl => _avatarUrl;
  String get locationName => _locationName;
  double get lat => _lat;
  double get lon => _lon;
  bool get isGuest => _supabaseService.currentUser == null;
  bool get notificationsEnabled => _notificationsEnabled;
  
  double get temp => _temp;
  String get weatherDesc => _weatherDesc;
  bool get isWeatherLoading => _isWeatherLoading;
  bool get isChatLoading => _isChatLoading;

  String get firstName {
    if (_userName == 'Guest' || _userName.isEmpty) return 'Guest';
    return _userName.split(' ').first;
  }

  String get timeBasedGreeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return _language == 'Twi' ? 'Maakye' : 'Good Morning';
    if (hour < 17) return _language == 'Twi' ? 'Maaha' : 'Good Afternoon';
    return _language == 'Twi' ? 'Maadwo' : 'Good Evening';
  }

  AppProvider() {
    _loadData();
    _tfLiteService.loadModel();
    _initTts();
  }

  Future<void> _loadData() async {
    final settingsBox = Hive.box('settings');
    _userName = settingsBox.get('userName', defaultValue: 'Guest');
    _avatarUrl = settingsBox.get('avatarUrl');
    _language = settingsBox.get('language', defaultValue: 'English');
    _themeMode = settingsBox.get('isDarkMode', defaultValue: false) ? ThemeMode.dark : ThemeMode.light;
    _locationName = settingsBox.get('locationName', defaultValue: 'Kumasi');
    _lat = settingsBox.get('lat', defaultValue: 6.6666);
    _lon = settingsBox.get('lon', defaultValue: -1.6163);
    _notificationsEnabled = settingsBox.get('notificationsEnabled', defaultValue: true);

    final historyBox = Hive.box('scan_history');
    final List<dynamic> historyData = historyBox.get('history', defaultValue: []);
    _history = historyData.map((e) => Prediction.fromMap(Map<String, dynamic>.from(e))).toList();

    final scheduleBox = Hive.box('schedules');
    final List<dynamic> scheduleData = scheduleBox.get('list', defaultValue: []);
    _schedules = scheduleData.map((e) => Schedule.fromMap(Map<String, dynamic>.from(e))).toList();
    
    if (_supabaseService.currentUser != null) {
      await _loadUserData();
      await syncWithCloud();
    }
    
    await fetchWeather();
    notifyListeners();
  }

  Future<void> fetchWeather() async {
    _isWeatherLoading = true;
    notifyListeners();
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current=temperature_2m,weather_code&timezone=auto';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _temp = data['current']['temperature_2m'].toDouble();
        _weatherDesc = _getWeatherDescription(data['current']['weather_code']);
      }
    } catch (e) {
      debugPrint('Weather fetch error: $e');
    } finally {
      _isWeatherLoading = false;
      notifyListeners();
    }
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Sunny';
    if (code <= 3) return 'Cloudy';
    if (code >= 51 && code <= 67) return 'Rainy';
    if (code >= 95) return 'Stormy';
    return 'Clear';
  }

  Future<void> syncWithCloud() async {
    try {
      final cloudScans = await _supabaseService.fetchScans();
      final cloudSchedules = await _supabaseService.fetchSchedules();
      
      _history = cloudScans;
      _schedules = cloudSchedules;
      
      _saveHistory();
      _saveSchedules();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Cloud sync error: $e');
    }
  }

  void _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    if (_language == 'Twi') {
      await _flutterTts.setLanguage("ak-GH");
    } else {
      await _flutterTts.setLanguage("en-US");
    }
    await _flutterTts.speak(text);
  }

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    Hive.box('settings').put('isDarkMode', isDarkMode);
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _notificationsEnabled = value;
    Hive.box('settings').put('notificationsEnabled', value);
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

  void setAvatarUrl(String? url) {
    _avatarUrl = url;
    Hive.box('settings').put('avatarUrl', url);
    notifyListeners();
  }

  void setGuestUser() {
    setUserName('Guest');
    setAvatarUrl(null);
  }

  void setLocation(double lat, double lon, String name) {
    _lat = lat;
    _lon = lon;
    _locationName = name;
    Hive.box('settings').put('lat', lat);
    Hive.box('settings').put('lon', lon);
    Hive.box('settings').put('locationName', name);
    fetchWeather();
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
      
      await fetchWeather();
      notifyListeners();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  final Map<String, Map<String, String>> _diseaseData = {
    'Black Rot': {
      'description': 'A serious bacterial disease causing V-shaped yellow lesions on leaf margins.',
      'treatment': 'Use disease-free seeds, rotate crops, and apply copper-based fungicides.',
      'twi_name': 'Black Rot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa bi a ɛma nhaban no ano yɛ akokoɔsradeɛ na ɛporɔ.',
      'twi_treatment': 'Fa aba a ho tɛ, sesa nnɔbae no, na fa nnuru a kɔperea wom gu so.',
      'image': 'assets/images/c2.jpg'
    },
    'Downy Mildew': {
      'description': 'A fungal disease appearing as yellow spots on top of leaves and white mold underneath.',
      'treatment': 'Improve air circulation, avoid overhead watering, and use appropriate fungicides.',
      'twi_name': 'Downy Mildew Yadeɛ',
      'twi_description': 'Yadeɛ yi ma nhaban no so yɛ nsuwa-nsuwa akokoɔsradeɛ na ase yɛ mfutuo fitaa.',
      'twi_treatment': 'Ma mframa mbɔ mu yiye, mma nsuo nka nhaban no so pii, na fa nnuru a ɛfata gu so.',
      'image': 'assets/images/c3.jpg'
    },
    'Alternaria Spot': {
      'description': 'Caused by Alternaria fungi, resulting in small, dark spots that often develop a target-like appearance.',
      'treatment': 'Practice crop rotation, use clean seed, and apply appropriate fungicides if severe.',
      'twi_name': 'Alternaria Spot Yadeɛ',
      'twi_description': 'Yadeɛ yi firi mmoawa a ɛma nhaban no so yɛ ntokuro ntokuro kɔkɔɔ anaa tuntum.',
      'twi_treatment': 'Sesa nnɔbae no, fa aba a ho tɛ yɛ adwuma, na fa nnuru a ɛfata gu so.',
      'image': 'assets/images/c4.jpg'
    },
    'Healthy': {
      'description': 'The cabbage leaf appears healthy with no visible signs of disease.',
      'treatment': 'Continue regular monitoring and maintain good agricultural practices.',
      'twi_name': 'Nhyehyɛe Pa',
      'twi_description': 'Kabeji nhaban yi ho yɛ, yadeɛ biara nni ho.',
      'twi_treatment': 'Kɔ so hwɛ wo nnɔbae no so yiye na kɔ so yɛ adwuma pa.',
      'image': 'assets/images/c1.jpg'
    },
  };

  Future<File?> _cropImage(String path, BuildContext context) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: _language == 'Twi' ? 'Twia mfonini no' : 'Focus on the Leaf',
            toolbarColor: colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            activeControlsWidgetColor: colorScheme.secondary,
            backgroundColor: theme.scaffoldBackgroundColor,
            statusBarColor: colorScheme.primary,
            showCropGrid: true,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: _language == 'Twi' ? 'Twia mfonini no' : 'Focus on the Leaf',
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );
      if (croppedFile != null) {
        return File(croppedFile.path);
      }
    } catch (e) {
      debugPrint('Cropping error: $e');
    }
    return null;
  }

  Future<void> pickImage(ImageSource source, BuildContext context) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      
      if (pickedFile != null) {
        // Essential delay to prevent race condition on some Android devices
        await Future.delayed(const Duration(milliseconds: 300));
        
        final croppedFile = await _cropImage(pickedFile.path, context);
        if (croppedFile == null) return; 

        _isLoading = true;
        _currentPrediction = null;
        _analysisMessage = 'SCANNING...';
        notifyListeners();

        await Future.delayed(const Duration(milliseconds: 500));
        _analysisMessage = 'EXTRACTING FEATURES...';
        notifyListeners();
        
        final result = await _tfLiteService.classifyImage(croppedFile.path);
        
        await Future.delayed(const Duration(milliseconds: 500));
        _analysisMessage = 'MODEL DECIDING...';
        notifyListeners();

        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await croppedFile.copy('${directory.path}/$fileName');
        _selectedImage = savedImage;

        if (result != null) {
          if (result['isLeaf'] == false) {
            _currentPrediction = Prediction(
              diseaseName: _language == 'Twi' ? 'Ɛnyɛ nhaban' : 'Not a Leaf',
              confidence: result['confidence'],
              description: _language == 'Twi' 
                  ? 'Mfonini a woyiiɛ no nsɛ kabeji nhaban anaa ɛnyɛ fann. Yɛpa wo kyɛw scan kabeji nhaban a ɛfata na fann. Yɛn AI no hu kabeji nhaban nko ara mprempren.' 
                  : 'The image captured does not look like a cabbage leaf or is not clear enough. Please try again with a clear photo of a cabbage leaf.',
              treatment: _language == 'Twi' ? 'Sane yɛ mfonini foforɔ.' : 'Please retake the photo.',
              imagePath: savedImage.path,
              dateTime: DateTime.now(),
              isAsset: false,
              isLeaf: false,
            );
          } else {
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
              isAsset: false,
              isLeaf: true,
            );
            
            _history.insert(0, _currentPrediction!);
            _saveHistory();
            
            if (!isGuest) {
              await _supabaseService.saveScan(_currentPrediction!, savedImage);
              await syncWithCloud();
            }
            _checkAndNotifyAnalytics();
          }
        } else {
          _currentPrediction = Prediction(
            diseaseName: _language == 'Twi' ? 'Mfomsoɔ' : 'Analysis Error',
            confidence: 0.0,
            description: _language == 'Twi' ? 'Yɛantumi anhunu yadeɛ no. Yɛpa wo kyɛw sane bɔ mmɔden.' : 'We could not analyze the image. Please try again.',
            treatment: _language == 'Twi' ? 'Sane yɛ mfonini foforɔ.' : 'Please retake the photo.',
            imagePath: savedImage.path,
            dateTime: DateTime.now(),
            isAsset: false,
          );
        }
      }
    } catch (e) {
      debugPrint('Error during selection/classification: $e');
      _currentPrediction = Prediction(
        diseaseName: 'Error',
        confidence: 0.0,
        description: 'A critical error occurred: $e',
        treatment: 'Please restart the app or try again.',
        imagePath: '',
        dateTime: DateTime.now(),
        isAsset: false,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkAndNotifyAnalytics() {
    if (!_notificationsEnabled) return;
    if (_history.length >= 3) {
      int healthyCount = _history.where((s) => s.diseaseName.toLowerCase().contains('healthy') || s.diseaseName.contains('Nhyehy')).length;
      int diseasedCount = _history.length - healthyCount;
      
      String summary = "You've completed ${_history.length} scans. $healthyCount healthy, $diseasedCount diseased.";
      if (_language == 'Twi') {
        summary = "Woayɛ nhwehwɛmu ${_history.length}. $healthyCount ho yɛ den, $diseasedCount yadeƐ bi wɔ ho.";
      }
      
      _notificationService.showInstantNotification(
        100,
        _language == 'Twi' ? 'Nkabom NhwehwƐmu' : 'Farm Health Summary',
        summary
      );
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String surname,
    required String dob,
    required String gender,
    required String profession,
    required String region,
    required String phone,
  }) async {
    final res = await _supabaseService.signUp(
      email: email,
      password: password,
      firstName: firstName,
      surname: surname,
      dob: dob,
      gender: gender,
      profession: profession,
      region: region,
      phone: phone,
    );
    if (res.user != null) {
      setUserName('$firstName $surname');
    }
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final res = await _supabaseService.signIn(email, password);
    if (res.user != null) {
      await _loadUserData();
      await syncWithCloud();
    }
    return res;
  }

  Future<void> _loadUserData() async {
    if (_supabaseService.currentUser != null) {
      final profile = await _supabaseService.fetchUserProfile();
      if (profile != null) {
        setUserName('${profile['first_name']} ${profile['surname']}');
        setAvatarUrl(profile['avatar_url']);
        setLocation(_lat, _lon, profile['region'] ?? 'Unknown');
      }
    }
  }

  Future<void> updateAvatar(File imageFile) async {
    final url = await _supabaseService.uploadAvatar(imageFile);
    if (url != null) {
      final profile = await _supabaseService.fetchUserProfile();
      if (profile != null) {
        await _supabaseService.updateUserProfile(
          firstName: profile['first_name'],
          surname: profile['surname'],
          profession: profile['profession'],
          region: profile['region'],
          phone: profile['phone_number'],
          avatarUrl: url,
        );
        setAvatarUrl(url);
      }
    }
  }

  Future<void> signOut() async {
    await _supabaseService.signOut();
    setGuestUser();
    _history.clear();
    _schedules.clear();
    _saveHistory();
    _saveSchedules();
    notifyListeners();
  }

  void setCurrentPrediction(Prediction prediction) {
    _currentPrediction = prediction;
    notifyListeners();
  }

  Future<void> deleteScan(Prediction prediction) async {
    _history.removeWhere((item) => item.dateTime == prediction.dateTime && item.imagePath == prediction.imagePath);
    
    if (!isGuest && (prediction.isNetwork || prediction.imagePath.startsWith('http'))) {
      await _supabaseService.deleteScan(prediction.imagePath);
    }

    if (!prediction.isAsset) {
      try {
        final file = File(prediction.imagePath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        debugPrint('Error deleting local file: $e');
      }
    }
    
    _saveHistory();
    notifyListeners();
  }

  Future<void> deleteMultipleScans(List<Prediction> scansToDelete) async {
    for (var scan in scansToDelete) {
      await deleteScan(scan);
    }
  }

  Future<void> deleteAllHistory() async {
    final scansToDelete = List<Prediction>.from(_history);
    for (var scan in scansToDelete) {
      await deleteScan(scan);
    }
  }

  void _saveHistory() {
    final historyBox = Hive.box('scan_history');
    final historyData = _history.map((e) => e.toMap()).toList();
    historyBox.put('history', historyData);
  }

  Future<void> addSchedule(Schedule schedule) async {
    _schedules.add(schedule);
    _schedules.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    _saveSchedules();
    
    if (_supabaseService.currentUser != null) {
      await _supabaseService.addSchedule(schedule);
    }

    notifyListeners();
  }

  Future<void> deleteSchedule(String id) async {
    _schedules.removeWhere((s) => s.id == id);
    _saveSchedules();
    
    if (!isGuest) {
      await _supabaseService.deleteSchedule(id);
    }
    
    notifyListeners();
  }

  void _saveSchedules() {
    final scheduleBox = Hive.box('schedules');
    final scheduleData = _schedules.map((e) => e.toMap()).toList();
    scheduleBox.put('list', scheduleData);
  }

  Future<String> askGemini(String prompt) async {
    _isChatLoading = true;
    notifyListeners();
    try {
      final reply = await _supabaseService.askGemini(prompt);
      return reply;
    } finally {
      _isChatLoading = false;
      notifyListeners();
    }
  }

  String tr(String key) {
    if (_language != 'Twi') return key;
    
    final twiMap = {
      'DASHBOARD': 'ADWUMAYƐBEA',
      'Scan your leaves for health status.': 'Hwɛ wo nnɔbae ahoɔden.',
      'Sunny': 'Wiem Ayɛ Hyɛ',
      'Scans': 'NhwehwƐmu',
      'Diagnosis Tools': 'NhwehwƐmu Akwan',
      'Camera': 'Kamera',
      'Gallery': 'Adaka',
      'Recent Scans': 'NhwehwƐmu a Atwam',
      'View all': 'Hwɛ ne nyinaa',
      'LIVE': 'ƐREKƆ SO',
      'Daily Recommendation': 'Afutuo',
      'Based on crop cycle': 'Ɛgyina nnɔbae mmerɛ so',
      'CROP CARE TIP': 'AFUTUO PA',
      'Home': 'Efie',
      'Farm Weather': 'Wiem mberɛ',
      'Weather': 'Wiem mberɛ',
      'Scan Schedule': 'Hyehyɛɛ',
      'Schedule': 'Hyehyɛɛ',
      'Field Analytics': 'Akontaabuo',
      'Analytics': 'Akontaabuo',
      'Scan History': 'Abakɔsɛm',
      'History': 'Abakɔsɛm',
      'Settings': 'Nhyehyɛe',
      'About Doctor': 'Fa fa ho',
      'Help & About': 'Mmoa ne Ho Asɛm',
      'Logout': 'Firi mu',
      'Standard Access': 'Mmoa Baako',
      'Pro Farmer': 'Okuafoɔ Panin',
      'Guest User': 'Ɔhɔhoɔ',
      'DIAGNOSIS': 'NHWEHWƐMU',
      'Description': 'Nkyerɛmu',
      'Recommended Treatment': 'SƐnea yƐsa yadeƐ no',
      'Back to Dashboard': 'Kɔ Fie',
      'Listen to Advice': 'Tie afutuo no',
      'Stop Listening': 'Gyae tie',
      'Tie afutuo no wɔ Twi mu': 'Tie afutuo no',
      'ANALYZING LEAF...': 'YƐREHWƐ NHABAN NO...',
      'Our AI is detecting diseases': 'YƐREHWƐ SƐ YADEƐ BIARA WƆ HO',
      'No history yet.\nStart by scanning a leaf!': 'Abakɔsɛm biara nni hɔ.\nFa scan nhaban bi fiti ase!',
      'Detection History': 'Nhwehwɛmu Abakɔsɛm',
      'Delete Scan?': 'Popa Nhwehwɛmu no?',
      'This action cannot be undone.': 'Sɛ wopopa a, ɛrentumi nsan mma bio.',
      'CANCEL': 'TWƐN',
      'DELETE': 'POPA',
      'Scan deleted': 'Yɛapopa nhwehwɛmu no',
      'Upcoming Schedule': 'Hyehyɛɛ a ɛreba',
      'No tasks scheduled.': 'Hyehyɛɛ biara nni hɔ.',
      'Scanning': 'NhwehwƐmu',
      'Watering': 'Nsuo gu',
      'Pruning': 'Nhyehyɛe',
      'Fertilizing': 'Duane gu',
      'Pest Control': 'Mmoawa kum',
      'Invalid Image': 'Mfonini no nyɛ papa',
      'Please scan a valid cabbage leaf. Our AI only recognizes cabbage leaves for now.': 'Yɛpa wo kyɛw scan kabeji nhaban a ɛfata. Yɛn AI no hu kabeji nhaban nko ara mprempren.',
      'Delete Selected?': 'Popa deɛ woapaw no?',
      'Delete All History?': 'Popa Abakɔsɛm nyinaa?',
      'Are you sure you want to delete all scans?': 'Wopɛ sɛ wopopa nhwehwƐmu nyinaa?',
      'ALL SCANS DELETED': 'YƐAPOPA NHWEHWƐMU NYINAA',
      'Selected': 'Paw',
      'Select Scans': 'Paw NhwehwƐmu',
      'Delete All': 'Popa Ne Nyinaa',
      'Delete Selected Scans': 'Popa NhwehwƐmu a woapaw',
      'Language': 'Kasa',
      'Dark Mode': 'Anadwo mberɛ',
      'Enable Notifications': 'Ma kwan ma nkaebɔ',
      'Receive scan reminders': 'Nya scan nkaebɔ',
      'About Doctor & AI': 'Fa fa Doctor ne AI ho',
      'App info and developer details': 'App ho asƐm ne nkurɔfoɔ a wɔyƐeƐ',
      'Appearance': 'SƐnea ɛteƐ',
      'Preferences': 'NhyehyƐe',
      'Help': 'Mmoa',
      'Select Date': 'Paw Da',
      'Plan Your Task': 'Hyehyɛ wo adwuma',
      'Reminder Time': 'Nkaebɔ mberɛ',
      'Set Reminder for': 'Hyehyɛ nkaebɔ ma',
      'SMART SUGGESTION FOR': 'AFUTUO MA',
      'Farm Planner': 'Afuo Nhyehyɛe',
      'Delete Schedule?': 'Popa Nhyehyɛe?',
      'Schedule deleted permanently': 'Yɛapopa nhyehyɛe no koraa',
      'CROP CARE TIP': 'AFUTUO PA',
      'Upcoming Schedule': 'Hyehyɛɛ a ɛreba',
      'Plan More': 'Hyehyɛ foforɔ',
      'No tasks scheduled.': 'Hyehyɛɛ biara nni hɔ.',
      'Recent Activity': 'Nhwehwɛmu a atwam',
      'See All': 'Hwɛ ne nyinaa',
      'Scan Analytics': 'Nhwehwɛmu akontaabuo',
      'Total Scans': 'Nhwehwɛmu nyinaa',
      'Next Task': 'Adwuma a ɛdi hɔ',
      'ACTIVE': 'ƐKƆ SO',
      'CABBAGE DOCTOR': 'KABEJI DOCTOR',
      'How to use': 'SƐnea wɔde di dwuma',
      'HOW TO DO IT': 'SƐNEA WƆYƐ NO',
      'Time': 'Mberɛ',
      'Add to Field Schedule': 'Fa ka nhyehyɛe ho',
      'EXPERT CHOICE': 'AFUTUO PA',
      'For': 'Ma',
      'Click to plan it below.': 'Pia ase ha na hyehyɛ.',
      'Scanning': 'NhwehwƐmu',
      'Watering': 'Nsuo gu',
      'Pruning': 'Nhyehyɛe',
      'Fertilizing': 'Duane gu',
      'Pest Control': 'Mmoawa kum',
      'Use AI to check for diseases early.': 'Fa AI hwehwɛ yadeɛ mu ntɛm.',
      'Maintain consistent soil moisture.': 'Hwɛ sɛ nsuo wɔ asase no mu.',
      'Remove damaged or infected parts.': 'Tu nhaban a ayɛ yadeɛ gu.',
      'Apply nitrogen-rich nutrients.': 'Fa duane gu mu.',
      'Monitor for caterpillars & aphids.': 'Hwɛ mmoawa ahorow.',
      'Walk diagonally across field': 'Fante-fante kɔ afuo mu',
      'Select 10 random leaves': 'Paw nhaban du',
      'Scan with Cabbage Doctor': 'Scan wɔ Cabbage Doctor mu',
      'Note high-risk areas': 'Hwɛ baabi a yadeɛ wɔ paa',
      'Check soil 2-inches deep': 'Hwɛ asase no mu paa',
      'Water at the base of plants': 'Gugu nsuo wɔ aseɛ',
      'Avoid wetting leaves': 'Mma nsuo nka nhaban',
      'Best done before 9 AM': 'Yɛ no anɔpa paa',
      'Identify V-shaped lesions': 'Hwehwɛ nhaban a ayɛ yadeɛ',
      'Use sterilized tools': 'Fa nninnuadeɛ a ho tɛ',
      'Remove lower yellow leaves': 'Tu nhaban a ayɛ kɔkɔɔ',
      'Dispose debris away from field': 'Tu gu baabi a ɛware',
      'Apply 3 weeks after planting': 'Yɛ no adapɛn mmiɛnsa akyi',
      'Side-dress 6 inches from stem': 'Fa gu nkyɛn kakra',
      'Water immediately after': 'Gugu nsuo ntɛm',
      'Follow local dosage guide': 'Di akwankyerɛ so',
      'Look under leaf surfaces': 'Hwɛ nhaban no ase',
      'Check for silk or holes': 'Hwɛ ntontan anaa ntokuro',
      'Identify beneficial insects': 'Hwɛ mmoawa pa',
      'Use organic neem spray if needed': 'Fa neem spray gu so',
      'No upcoming tasks.': 'Hyehyɛɛ biara nni hɔ.',
      'Selected Scans Deleted': 'Nhwehwɛmu a woapaw no yɛapopa',
    };

    return twiMap[key] ?? key;
  }

  String getSuggestedActivity(DateTime day) {
    if (_history.isNotEmpty) {
      String latestDisease = _history.first.diseaseName;
      if (latestDisease.contains('Black Rot') && (day.weekday == DateTime.tuesday || day.weekday == DateTime.friday)) {
        return _language == 'Twi' ? 'Wuo Aduane ma Black Rot' : 'Copper Fungicide Spray';
      }
      if (latestDisease.contains('Downy') && day.weekday == DateTime.monday) {
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

  @override
  void dispose() {
    _tfLiteService.dispose();
    super.dispose();
  }
}
