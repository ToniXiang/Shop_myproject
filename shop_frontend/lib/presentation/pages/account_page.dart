import 'package:shop_frontend/presentation/presentation.dart';
import 'package:shop_frontend/data/data.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  AccountPageState createState() => AccountPageState();
}

class AccountPageState extends State<AccountPage> {
  String username = 'user';
  String email = 'user@example.com';
  final storage = FlutterSecureStorage();
  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      // 使用新的身份驗證服務獲取用戶資訊
      final userInfo = await AuthService.getUserInfo();
      if (userInfo != null) {
        setState(() {
          username = userInfo['username'] ?? 'user';
          email = userInfo['email'] ?? 'user@example.com';
        });
      } else {
        // 如果本地沒有用戶資訊，嘗試從 API 獲取
        final data = await ApiService.authenticatedGetRequest('api/user/info');
        setState(() {
          username = data['username'] ?? 'user';
          email = data['email'] ?? 'user@example.com';
        });
      }
    } catch (e) {
      debugPrint('取得使用者資訊失敗: $e');
      // 如果取得用戶資訊失敗，可能是 token 過期，嘗試刷新
      final refreshSuccess = await AuthService.refreshToken();
      if (refreshSuccess) {
        // 刷新成功後重試
        _fetchUserInfo();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 3),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              const SizedBox(width: 48),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('個人資訊'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('付款方式'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('收貨地址'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
