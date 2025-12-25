import 'package:practice0419_frontend/presentation/presentation.dart';
import 'package:provider/provider.dart';
import 'package:practice0419_frontend/core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'dart:io';

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    doWhenWindowReady(() {
      const initialSize = Size(windowWidth, windowHeight);
      appWindow.minSize = initialSize;
      appWindow.maxSize = initialSize;
      appWindow.size = initialSize;
      appWindow.alignment = Alignment.center;
      appWindow.title = AppConfig.appTitle;
      appWindow.show();
    });
  }
}
void main() {
  setupWindow(); 
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '資工購物平台',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.currentThemeMode,
          onGenerateRoute: (RouteSettings settings) {
            return MaterialPageRoute(builder: (context) => const SplashScreen());
          },
        );
      },
    );
  }
}