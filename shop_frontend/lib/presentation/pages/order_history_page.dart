import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shop_frontend/presentation/presentation.dart';
import 'package:shop_frontend/data/data.dart';
import 'package:intl/intl.dart';
import 'package:shop_frontend/core/core.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = fetchOrders();
  }

  Future<List<dynamic>> fetchOrders() async {
    final accessToken = await AuthService.getAccessToken();

    if (accessToken == null) {
      throw Exception('未登入');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}/api/orders');

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final currentToken = await AuthService.getAccessToken();
        if (currentToken == null) {
          throw Exception('認證 Token 無效');
        }

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $currentToken',
          },
        );
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is List) {
            return List<dynamic>.from(data);
          } else if (data is Map && data.containsKey('data')) {
            // Handle response format: {"message":"訂單列表取得成功","data":[...]}
            return List<dynamic>.from(data['data'] ?? []);
          } else {
            throw Exception(data['message'] ?? '獲取訂單失敗');
          }
        } else if (response.statusCode == 401 && attempt == 0) {
          final refreshed = await AuthService.refreshToken();
          if (!refreshed) {
            throw Exception('認證 Token 無效');
          }
          continue;
        } else {
          try {
            final errorData = json.decode(response.body);
            throw Exception(
              errorData['error'] ?? errorData['message'] ?? '獲取訂單失敗',
            );
          } catch (jsonError) {
            throw Exception('獲取訂單失敗: HTTP ${response.statusCode}');
          }
        }
      } catch (e) {
        if (attempt == 1 || e.toString().contains('認證')) {
          rethrow;
        }
        // Continue to next attempt for network errors
      }
    }

    throw Exception('網路連線錯誤，請檢查網路狀態');
  }

  void showCancelDialog(BuildContext context, int orderId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('取消訂單確認',style: TextStyle(fontSize: 20)),
          content: Text('您確定要取消訂單 #$orderId 嗎？'),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white
              ),
              child: const Text('確定取消'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelOrder(orderId);
              },
            ),
            TextButton(
              child: const Text('不要取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelOrder(int orderId) async {
    try {
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          final accessToken = await AuthService.getAccessToken();
          if (accessToken == null) {
            throw Exception('認證 Token 無效');
          }

          final response = await http.delete(
            Uri.parse('${ApiConstants.baseUrl}/api/orders/$orderId/cancel/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          );

          if (response.statusCode == 200) {
            final responseData = json.decode(response.body);
            setState(() {
              _ordersFuture = fetchOrders();
            });
            if (!mounted) return;
            MessageService.showMessage(
              context,
              responseData['message'] ?? '訂單取消成功',
            );
            return;
          } else if (response.statusCode == 401 && attempt == 0) {
            final refreshed = await AuthService.refreshToken();
            if (!refreshed) {
              throw Exception('認證 Token 無效');
            }
            continue;
          } else {
            final errorData = json.decode(response.body);
            throw Exception(errorData['message'] ?? '取消訂單失敗');
          }
        } catch (retryError) {
          if (attempt == 1) {
            rethrow;
          }
        }
      }
    } catch (e) {
      if (e.toString().contains('認證 Token 無效')) {
        if (!mounted) return;
        MessageService.showMessage(context, '認證 Token 無效，請重新登入');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        if (!mounted) return;
        MessageService.showMessage(context, '取消訂單失敗: ');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _ordersFuture = fetchOrders();
          });
          await _ordersFuture;
        },
        child: FutureBuilder<List<dynamic>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "載入訂單歷史失敗",
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "請檢查網路連線狀態後重試",
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _ordersFuture = fetchOrders();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('重新載入'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 80,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "您還沒有任何訂單",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "開始購物來建立您的第一筆訂單吧！",
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('開始購物'),
                        style: TextButton.styleFrom(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          foregroundColor: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _ordersFuture = fetchOrders();
                        });
                      },
                      child: const Text('重新整理'),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderId = order['id'];
                final createdAt =
                    DateTime.parse(order['created_at'].toString()).toLocal();
                final formatted = DateFormat(
                  'yyyy/MM/dd HH:mm',
                ).format(createdAt);
                final items = order['items'] as List<dynamic>;

                double total = 0;
                for (var item in items) {
                  total +=
                      double.parse(item['product_price']) * item['quantity'];
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ExpansionTile(
                    leading: const Icon(Icons.receipt_long),
                    collapsedBackgroundColor: theme.colorScheme.surface,
                    backgroundColor: theme.colorScheme.surface,
                    title: Text("訂單 #$orderId"),
                    subtitle: Text("建立時間 $formatted"),
                    children: [
                      Column(
                        children:
                            items.map((item) {
                              return ListTile(
                                title: Text(item['product_name']),
                                subtitle: Text("數量: ${item['quantity']}"),
                                trailing: Text(
                                  "\$${(double.parse(item['product_price']) * item['quantity']).toStringAsFixed(2)}",
                                ),
                              );
                            }).toList(),
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                showCancelDialog(context, orderId);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white
                                ),
                              child: const Text("取消訂單"),
                            ),
                            Text(
                              "總計: ${total.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      drawer: const CustomDrawer(),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 2),
    );
  }
}
