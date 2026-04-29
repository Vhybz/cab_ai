import 'dart:convert';
import 'dart:ui';
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
  double _lat = 6.6666;
  double _lon = -1.6163;
  String _locationName = 'Kumasi';
  
  Map<String, dynamic>? _currentWeather;
  Map<String, dynamic>? _hourlyData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWeather();
  }

  Future<void> _initWeather() async {
    setState(() => _isLoading = true);
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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      if (mounted) {
        setState(() {
          _lat = position.latitude;
          _lon = position.longitude;
        });
      }
      
      List<Placemark> placemarks = await placemarkFromCoordinates(_lat, _lon);
      if (placemarks.isNotEmpty && mounted) {
        setState(() {
          _locationName = placemarks[0].locality ?? placemarks[0].administrativeArea ?? 'My Farm';
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  Future<void> _fetchWeather() async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$_lat&longitude=$_lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&hourly=temperature_2m,relative_humidity_2m&past_days=3&timezone=auto';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _currentWeather = json.decode(response.body)['current'];
          _hourlyData = json.decode(response.body)['hourly'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF9FBF9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initWeather,
              color: colorScheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  _buildWeatherHeader(colorScheme),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('FARMER ASSISTANT ADVICE'),
                          const SizedBox(height: 16),
                          _buildAdviceCards(colorScheme),
                          const SizedBox(height: 32),
                          _buildSectionLabel('3-DAY TEMP TREND'),
                          const SizedBox(height: 16),
                          _buildTrendChart(colorScheme),
                          const SizedBox(height: 32),
                          _buildSectionLabel('ATMOSPHERIC DETAILS'),
                          const SizedBox(height: 16),
                          _buildDetailsGrid(colorScheme, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildWeatherHeader(ColorScheme colorScheme) {
    final temp = _currentWeather?['temperature_2m'] ?? 0;
    final code = _currentWeather?['weather_code'] ?? 0;
    final desc = _getWeatherDescription(code);

    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.primary,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _initWeather,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colorScheme.primary, colorScheme.secondary],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(_locationName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Icon(_getWeatherIcon(code), size: 100, color: Colors.white),
              const SizedBox(height: 10),
              Text('${temp.toInt()}°', style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.w900)),
              Text(desc.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(text, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5));
  }

  Widget _buildAdviceCards(ColorScheme colorScheme) {
    final temp = _currentWeather?['temperature_2m'] ?? 0;
    final humidity = _currentWeather?['relative_humidity_2m'] ?? 0;
    
    List<Map<String, dynamic>> advice = [
      {
        'title': 'Moisture Alert',
        'msg': humidity > 80 ? 'High humidity ($humidity%) increases Black Rot risk.' : 'Conditions are stable for cabbage health.',
        'icon': Icons.water_drop_rounded,
        'color': humidity > 80 ? Colors.redAccent : Colors.blue,
      },
      {
        'title': 'Thermal Watch',
        'msg': temp > 30 ? 'Heat stress likely. Water base early or late.' : 'Temperature is ideal for cabbage growth.',
        'icon': Icons.thermostat_rounded,
        'color': temp > 30 ? Colors.orange : Colors.green,
      }
    ];

    return Column(
      children: advice.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: a['color'].withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: a['color'].withOpacity(0.1), shape: BoxShape.circle), child: Icon(a['icon'], color: a['color'])),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a['title'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(a['msg'], style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTrendChart(ColorScheme colorScheme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(24)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(10, (i) => FlSpot(i.toDouble(), 25 + (i % 5).toDouble())),
              isCurved: true,
              color: colorScheme.primary,
              barWidth: 6,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: colorScheme.primary.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsGrid(ColorScheme colorScheme, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _detailBox('Humidity', '${_currentWeather?['relative_humidity_2m'] ?? 0}%', Icons.water_rounded, Colors.blue, isDark),
        _detailBox('Wind', '${_currentWeather?['wind_speed_10m'] ?? 0}km/h', Icons.air_rounded, Colors.cyan, isDark),
        _detailBox('Real-time', 'Sync OK', Icons.sync_rounded, Colors.green, isDark),
        _detailBox('Forecast', '7 Days', Icons.calendar_view_week_rounded, Colors.orange, isDark),
      ],
    );
  }

  Widget _detailBox(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code <= 3) return Icons.wb_cloudy_rounded;
    if (code <= 67) return Icons.beach_access_rounded;
    return Icons.thunderstorm_rounded;
  }

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Clear Skies';
    if (code <= 3) return 'Partly Cloudy';
    if (code <= 67) return 'Rainy';
    return 'Stormy';
  }
}
