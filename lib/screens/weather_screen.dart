import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  // Default coordinates (Kumasi, Ghana)
  double _lat = 6.6666;
  double _lon = -1.6163;
  String _locationName = 'Kumasi';
  
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _hourlyData;
  bool _isLoading = true;
  String _errorMessage = '';

  // List of major farming regions in Ghana for manual selection
  final Map<String, List<double>> _regions = {
    'Kumasi (Ashanti)': [6.6666, -1.6163],
    'Accra (Greater Accra)': [5.6037, -0.1870],
    'Tamale (Northern)': [9.4034, -0.8424],
    'Sunyani (Bono)': [7.3349, -2.3123],
    'Ho (Volta)': [6.6101, 0.4785],
    'Koforidua (Eastern)': [6.0784, -0.2713],
    'Takoradi (Western)': [4.8951, -1.7554],
    'Bolgatanga (Upper East)': [10.7856, -0.8514],
    'Wa (Upper West)': [10.0601, -2.5019],
  };

  @override
  void initState() {
    super.initState();
    _initWeather();
  }

  Future<void> _initWeather() async {
    await _getCurrentLocation();
    await _fetchWeather();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      
      if (permission == LocationPermission.deniedForever) return;

      // Increased accuracy to ensure precise location detection
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = position.latitude;
        _lon = position.longitude;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lon);
      if (placemarks.isNotEmpty) {
        setState(() {
          _locationName = placemarks[0].locality ?? placemarks[0].administrativeArea ?? 'My Farm';
        });
      }
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m&past_days=7&timezone=auto';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _currentWeather = data['current'];
          _hourlyData = data['hourly'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load weather data.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while fetching weather.';
        _isLoading = false;
      });
    }
  }

  void _onRegionSelected(String regionName) {
    final coords = _regions[regionName]!;
    setState(() {
      _lat = coords[0];
      _lon = coords[1];
      _locationName = regionName;
    });
    _fetchWeather();
  }

  String _getFarmAdvice(int weatherCode, double temp, List<dynamic> humidities) {
    double avgHumidity = 0;
    if (humidities.isNotEmpty) {
      int startIndex = humidities.length > 24 ? humidities.length - 48 : 0;
      int endIndex = humidities.length > 24 ? humidities.length - 24 : humidities.length;
      var lastDayHumid = humidities.sublist(startIndex, endIndex);
      avgHumidity = lastDayHumid.map((e) => e as num).reduce((a, b) => a + b) / lastDayHumid.length;
    }

    if (avgHumidity > 85) {
      return 'High humidity detected. This increases risk of fungal diseases. Inspect leaves for spots.';
    } else if (weatherCode >= 51 && weatherCode <= 67) {
      return 'Rain detected. Avoid applying fertilizers now. Ensure proper drainage.';
    } else if (temp > 30) {
      return 'High heat detected. Cabbages need more water. Consider providing shade.';
    }
    return 'Conditions are stable. Continue with your scheduled maintenance.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farm Weather', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on_rounded),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (context) => _buildLocationPicker(),
              );
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchWeather,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMainWeatherCard(colorScheme, isDark),
                    const SizedBox(height: 24),
                    _buildDecisionCard(colorScheme),
                    const SizedBox(height: 24),
                    Text('7-Day Temperature Trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildTrendChart(colorScheme, isDark),
                    const SizedBox(height: 24),
                    _buildDetailsGrid(colorScheme),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Select Farm Region', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          leading: const Icon(Icons.my_location, color: Colors.green),
          title: const Text('Use Current GPS Location'),
          onTap: () {
            Navigator.pop(context);
            _initWeather();
          },
        ),
        const Divider(),
        Expanded(
          child: ListView(
            children: _regions.keys.map((name) => ListTile(
              title: Text(name),
              onTap: () {
                Navigator.pop(context);
                _onRegionSelected(name);
              },
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMainWeatherCard(ColorScheme colorScheme, bool isDark) {
    final temp = _currentWeather!['temperature_2m'];
    final code = _currentWeather!['weather_code'];
    final desc = _getWeatherDescription(code);

    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(_locationName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(DateFormat('EEEE, MMM dd').format(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
          const SizedBox(height: 20),
          Icon(_getWeatherIcon(code), size: 80, color: Colors.white),
          const SizedBox(height: 10),
          Text('${temp.toStringAsFixed(1)}°C', style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900)),
          Text(desc.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDecisionCard(ColorScheme colorScheme) {
    final code = _currentWeather!['weather_code'];
    final temp = _currentWeather!['temperature_2m'].toDouble();
    final advice = _getFarmAdvice(code, temp, _hourlyData!['relative_humidity_2m']);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text('Smart Farm Decision', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 16),
          Text(advice, style: const TextStyle(fontSize: 15, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildTrendChart(ColorScheme colorScheme, bool isDark) {
    final List<dynamic> temps = _hourlyData!['temperature_2m'];
    List<double> dailyAvg = [];
    for (int i = 0; i < 7; i++) {
      var dayTemps = temps.sublist(i * 24, (i + 1) * 24);
      double avg = dayTemps.map((e) => e as num).reduce((a, b) => a + b) / 24;
      dailyAvg.add(avg);
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(dailyAvg.length, (i) => FlSpot(i.toDouble(), dailyAvg[i])),
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: colorScheme.primary.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(ColorScheme colorScheme) {
    final humidity = _currentWeather!['relative_humidity_2m'];
    final wind = _currentWeather!['wind_speed_10m'];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildDetailItem(colorScheme, Icons.water_drop_rounded, '$humidity%', 'Humidity'),
        _buildDetailItem(colorScheme, Icons.air_rounded, '${wind}km/h', 'Wind Speed'),
        _buildDetailItem(colorScheme, Icons.gps_fixed_rounded, 'Lat: ${_lat.toStringAsFixed(2)}', 'Latitude'),
        _buildDetailItem(colorScheme, Icons.update_rounded, 'Real-time', 'Open-Meteo'),
      ],
    );
  }

  Widget _buildDetailItem(ColorScheme colorScheme, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy_rounded;
    if (code >= 51 && code <= 67) return Icons.beach_access_rounded;
    if (code >= 95 && code <= 99) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }

  String _getWeatherDescription(int code) {
    switch (code) {
      case 0: return 'Clear sky';
      case 1: return 'Mainly clear';
      case 2: return 'Partly cloudy';
      case 3: return 'Overcast';
      case 51: return 'Drizzle';
      case 61: return 'Slight rain';
      case 63: return 'Moderate rain';
      case 65: return 'Heavy rain';
      case 95: return 'Thunderstorm';
      default: return 'Cloudy';
    }
  }
}
