import 'package:shop_frontend/presentation/presentation.dart';
import 'package:provider/provider.dart';
import 'package:shop_frontend/data/data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shop_frontend/core/core.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {
  final passwordController = TextEditingController();
  final verificationPasswordController = TextEditingController();
  final verificationCodeController = TextEditingController();
  Map<String, dynamic>? userInfo;
  bool isLoading = true;
  String username = 'user';
  String email = 'user@example.com';

  Future<void> getVerificationCode() async {
    try {
      final response = await ApiService.authenticatedPostRequest(
        'api/send_verification_code/',
        {'email': email},
      );
      if (!mounted) return;
      MessageService.showMessage(context, response['message']);
    } catch (e) {
      MessageService.showMessage(context, '發送驗證碼失敗: $e');
    }
  }

  Future<void> changePassword() async {
    final newPassword = passwordController.text;
    final confirmPassword = verificationPasswordController.text;
    final code = verificationCodeController.text;

    if (newPassword != confirmPassword) {
      MessageService.showMessage(context, '密碼與確認密碼不一致');
      return;
    }
    try {
      final responseData = await ApiService.authenticatedPostRequest(
        'api/reset_password/',
        {'email': email, 'password': newPassword, 'code': code},
      );
      if (!mounted) return;
      MessageService.showMessage(context, responseData['message']);
      // 清空密碼輸入框
      passwordController.clear();
      verificationPasswordController.clear();
      verificationCodeController.clear();
    } catch (e) {
      MessageService.showMessage(context, '修改密碼失敗: $e');
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final info = await AuthService.getUserInfo();
      setState(() {
        userInfo = info;
        if (info != null) {
          username = info['username'] ?? 'user';
          email = info['email'] ?? 'user@example.com';
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        MessageService.showMessage(context, '載入用戶資料失敗: $e');
      }
    }
  }

  Future<void> _refreshToken() async {
    try {
      setState(() {
        isLoading = true;
      });

      final success = await AuthService.refreshToken();

      setState(() {
        isLoading = false;
      });

      if (mounted) {
        if (success) {
          MessageService.showMessage(context, 'Token 刷新成功');
        } else {
          MessageService.showMessage(context, 'Token 刷新失敗');
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        MessageService.showMessage(context, 'Token 刷新錯誤: $e');
      }
    }
  }

  void _logout() {
    MessageService.showLogoutDialog(context);
  }

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    String themeName = Provider.of<ThemeProvider>(context).getThemeName();
    final theme = Theme.of(context);

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('設定',style: TextStyle(color: theme.colorScheme.onSurface))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('設定',style: TextStyle(color: theme.colorScheme.onSurface))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用戶資訊卡片
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '用戶資訊',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (userInfo != null) ...[
                    _buildInfoRow('用戶名稱', userInfo!['username'] ?? '未知'),
                    _buildInfoRow('電子郵件', userInfo!['email'] ?? '未知'),
                    if (userInfo!.containsKey('user_id'))
                      _buildInfoRow('用戶 ID', userInfo!['user_id'].toString()),
                  ] else
                    const Text('無法載入用戶資訊'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Token 管理區域
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Token 管理',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _refreshToken,
                      icon: const Icon(Icons.refresh),
                      label: const Text('手動刷新 Token'),
                      style: TextButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '系統會自動刷新 access token，但您也可以手動刷新',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: .6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 密碼修改區域
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '密碼管理',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PasswordInput(
                    context: context,
                    labelText: '新密碼',
                    hintText: '輸入新密碼',
                    icon: Icon(Icons.lock_outline),
                    controller: passwordController,
                  ),
                  const SizedBox(height: 12),
                  _PasswordInput(
                    context: context,
                    labelText: '確認密碼',
                    hintText: '再次輸入',
                    icon: Icon(Icons.lock_outline),
                    controller: verificationPasswordController,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: getVerificationCode,
                        style: ElevatedButton.styleFrom(
                          side: BorderSide(color: theme.colorScheme.primary),
                        ),
                        child: const Text("獲取驗證碼"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PasswordInput(
                    context: context,
                    labelText: '驗證碼',
                    hintText: '輸入驗證碼',
                    icon: Icon(Icons.verified_user_outlined),
                    controller: verificationCodeController,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: changePassword,
                      style: TextButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.primary),
                      ),
                      child: const Text("更改密碼"),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.palette),
                    title: Text(
                      '主題',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text("淺色"),
                        selected: themeName == "淺色模式",
                        onSelected: (_) {
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).setThemeMode(AppThemeMode.light);
                          setState(() => themeName = "淺色模式");
                        },
                      ),
                      ChoiceChip(
                        label: const Text("深色"),
                        selected: themeName == "深色模式",
                        onSelected: (_) {
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).setThemeMode(AppThemeMode.dark);
                          setState(() => themeName = "深色模式");
                        },
                      ),
                      ChoiceChip(
                        label: const Text("系統"),
                        selected: themeName == "系統預設",
                        onSelected: (_) {
                          Provider.of<ThemeProvider>(
                            context,
                            listen: false,
                          ).setThemeMode(AppThemeMode.system);
                          setState(() => themeName = "系統預設");
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Card(
            color: theme.colorScheme.surface,
            child: Column(
              children: [
                Tooltip(
                  message: '可確認版本更新狀況',
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('GitHub 儲存庫'),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () async {
                      const url =
                          'https://github.com/ChenGuoXiang940/SC2_myproject';
                      final Uri uri = Uri.parse(url);
                      if (await canLaunchUrl(uri) && context.mounted) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text("不能開啟網址")));
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 登出按鈕
          Card(
            color: theme.colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '帳戶操作',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('登出'),
                      style: TextButton.styleFrom(
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PasswordInput extends StatefulWidget {
  final BuildContext context;
  final String labelText;
  final String hintText;
  final Icon icon;
  final TextEditingController controller;

  const _PasswordInput({
    required this.context,
    required this.labelText,
    required this.hintText,
    required this.icon,
    required this.controller,
  });

  @override
  State<_PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<_PasswordInput> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: widget.icon,
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: _toggleVisibility,
        ),
      ),
    );
  }
}
