import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/audio_player_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Android system navigation bar & status bar to blend with Dark/Lime theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.darkBackground,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(const SonicFormApp());
}

class SonicFormApp extends StatefulWidget {
  const SonicFormApp({super.key});

  @override
  State<SonicFormApp> createState() => _SonicFormAppState();
}

class _SonicFormAppState extends State<SonicFormApp> {
  late final AudioPlayerService _playerService;

  @override
  void initState() {
    super.initState();
    _playerService = AudioPlayerService();
  }

  @override
  void dispose() {
    _playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SonicForm',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      home: HomeScreen(playerService: _playerService),
    );
  }
}
