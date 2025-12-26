import 'package:flutter/material.dart';
import 'package:shop_frontend/data/services/auth_service.dart';
import 'package:shop_frontend/presentation/pages/login_page.dart';
import 'package:shop_frontend/presentation/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // 等待一小段時間顯示啟動畫面
    await Future.delayed(const Duration(milliseconds: 1500));
    
    try {
      // 檢查是否已登入
      final isLoggedIn = await AuthService.isLoggedIn();
      
      if (!mounted) return;
      
      if (isLoggedIn) {
        // 已登入，導航到主頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // 未登入，導航到登入頁面
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      // 發生錯誤時，導航到登入頁面
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 應用 Logo
            const FlutterLogo(size: 120),
            const SizedBox(height: 24),
            
            // 應用標題
            Text(
              "scie 購物平台",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            
            // 載入指示器
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            
            Text(
              "正在檢查身份驗證狀態...",
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}