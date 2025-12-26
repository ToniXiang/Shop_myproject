import 'package:shop_frontend/presentation/presentation.dart';
import 'package:shop_frontend/data/data.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool isLoading = false;
  bool isRegister = false;
  void _login() async {
    try {
      setState(() {
        isLoading = true;
      });
      final responseData = await ApiService.postRequest('api/login/', {
        'email': emailController.text,
        'password': passwordController.text,
      });

      // 檢查返回的 token 和用戶信息
      if (responseData.containsKey('access_token') &&
          responseData.containsKey('refresh_token')) {
        String accessToken = responseData['access_token'] ?? "";
        String refreshToken = responseData['refresh_token'] ?? "";
        String username = responseData['username'] ?? "未知使用者";

        // 準備用戶信息
        Map<String, dynamic> userInfo = {
          'username': username,
          'email': emailController.text,
          if (responseData.containsKey('user_id'))
            'user_id': responseData['user_id'],
        };

        // 使用 AuthService 保存身份驗證資料
        await AuthService.saveAuthData(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userInfo: userInfo,
          expiresIn: responseData['expires_in'] ?? 3600, // 預設 1 小時
        );

        // 驗證 token 是否有效
        final isValid = await AuthService.validateToken();
        if (!isValid) {
          throw Exception('Token 驗證失敗');
        }

        if (mounted) {
          MessageService.showMessage(
            context,
            responseData['message'] + "  歡迎：$username",
          );
        }

        setState(() {
          isLoading = false;
        });

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        emailController.clear();
        passwordController.clear();
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          MessageService.showMessage(context, "缺少必要的身份驗證資料");
        }
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, '$e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _sendCode() async {
    try {
      final responseData = await ApiService.postRequest(
        'api/send_verification_code/',
        {'email': emailController.text},
      );
      if (mounted) {
        // 驗證碼僅能從後端取得，為了模擬安全性不會顯示在前端
        MessageService.showMessage(context, responseData['message']);
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, '$e');
      }
    }
  }

  void _register() async {
    try {
      isLoading = true;
      final responseData = await ApiService.postRequest('api/register/', {
        'email': emailController.text,
        'username': "新用戶",
        'password': passwordController.text,
        'verification_code': codeController.text,
      });
      if (mounted) {
        MessageService.showMessage(context, responseData['message']);
      }
    } catch (e) {
      if (mounted) {
        MessageService.showMessage(context, '$e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _switchRegister() {
    setState(() {
      isRegister = !isRegister;
    });
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
      obscureText: obscureText,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const FlutterLogo(size: 100),
              Text(
                "scie 購物平台",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              _buildTextInput(
                context: context,
                controller: emailController,
                label: '電子郵件',
              ),
              const SizedBox(height: 16),
              if (isRegister)
                Row(
                  children: [
                    Expanded(
                      child: _buildTextInput(
                        context: context,
                        controller: codeController,
                        label: '驗證碼(僅註冊需要)',
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _sendCode, child: const Text('發送驗證碼')),
                  ],
                ),
              if (isRegister) const SizedBox(height: 16),
              _PasswordInput(controller: passwordController, label: '密碼'),
              const SizedBox(height: 32),
              if (isRegister)
                ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white
                  ),
                  child: const Text('註冊'),
                )
              else
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white
                  ),
                  child: const Text('登入'),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _switchRegister,
                child: Text(isRegister ? '切換登入頁面' : '切換註冊頁面'),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                CircularProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(Colors.blue),
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          Icons.person_outline,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      style: TextStyle(fontSize: 14),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  const _PasswordInput({required this.controller, required this.label});
  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(fontSize: 14, color: theme.colorScheme.outline),
        prefixIcon: Icon(
          Icons.lock_outline,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: theme.colorScheme.surface,
      ),
      style: TextStyle(fontSize: 14),
    );
  }
}
