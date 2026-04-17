import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/app_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from cab.env
  try {
    await dotenv.load(fileName: "cab.env");
  } catch (e) {
    debugPrint('Warning: Could not load cab.env file: $e');
  }
  
  // Initialize Supabase with your credentials
  await Supabase.initialize(
    url: 'https://xshzslaaqcinvhlzudxt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhzaHpzbGFhcWNpbnZobHp1ZHh0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzNjUzNTIsImV4cCI6MjA5MTk0MTM1Mn0.LjeSqui4AKyiF6S_cqqWa8haJRfMtrgIAReM0Az_qVw',
  );
  
  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('scan_history');
  await Hive.openBox('schedules');
  
  // Initialize notification service
  await NotificationService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const CabbageDoctorApp(),
    ),
  );
}

class CabbageDoctorApp extends StatelessWidget {
  const CabbageDoctorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          title: 'Cabbage Doctor',
          debugShowCheckedModeBanner: false,
          themeMode: provider.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              primary: const Color(0xFF2E7D32),
              brightness: Brightness.light,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2E7D32),
              primary: const Color(0xFF4CAF50),
              brightness: Brightness.dark,
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              clipBehavior: Clip.antiAlias,
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
