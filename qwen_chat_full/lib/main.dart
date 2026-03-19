import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/chat_screen.dart';
import 'screens/model_download_screen.dart';
import 'services/model_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0D1117),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const QwenChatApp());
}

class QwenChatApp extends StatelessWidget {
  const QwenChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qwen Chat - Full Quality',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        primaryColor: const Color(0xFF00BCD4),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BCD4),
          secondary: Color(0xFF00838F),
          surface: Color(0xFF161B22),
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF161B22),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const AppEntryPoint(),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  bool _modelsReady = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkModels();
  }

  Future<void> _checkModels() async {
    final manager = ModelManager();
    final ready = await manager.areAllModelsReady();
    setState(() {
      _modelsReady = ready;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D1117),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
        ),
      );
    }

    if (!_modelsReady) {
      return ModelDownloadScreen(
        onDownloadComplete: () {
          setState(() => _modelsReady = true);
        },
      );
    }

    return const ChatScreen();
  }
}
