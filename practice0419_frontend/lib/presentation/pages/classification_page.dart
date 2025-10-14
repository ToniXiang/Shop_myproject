import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:practice0419_frontend/presentation/presentation.dart';
import 'package:practice0419_frontend/data/data.dart';

class ClassificationPage extends StatefulWidget {
  const ClassificationPage({super.key});
  @override
  ClassificationPageState createState() => ClassificationPageState();
}

class ClassificationPageState extends State<ClassificationPage> {
  late Future<List<Map<String, dynamic>>> _productsFuture;
  final storage = FlutterSecureStorage();
  final Set<int> selectedProducts = {};
  int selectedPageIndex = 0;
  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final responseData = await ApiService.getRequest('api/products/');
      final List products = responseData['data'] ?? [];

      return products.map<Map<String, dynamic>>((product) {
        return {
          'name': product['name'] ?? '未命名商品',
          'price': product['price'] ?? 0,
          'quantity': product['quantity'] ?? 1,
        };
      }).toList();
    } catch (e) {
      throw Exception('$e');
    }
  }

  void pushOrder() async {
    final products = await _productsFuture;
    final selectedItems =
        selectedProducts.map((index) {
          final product = products[index];
          return {
            'product_name': product['name'],
            'product_price': product['price'],
            'quantity': product['quantity'],
          };
        }).toList();
    try {
      final currentToken = await AuthService.getAccessToken();
      if (currentToken == null) return;
      final responseData = await ApiService.postRequest('api/orders/', {
        'products': selectedItems,
      }, token: currentToken);
      if (!mounted) return;
      MessageService.showMessage(context, responseData['message']);
    } catch (e) {
      if (!mounted) return;
      MessageService.showMessage(context, '$e');
      return;
    }
    setState(() {
      for (var index in selectedProducts) {
        products[index]['quantity'] = 1;
      }
      selectedProducts.clear();
    });
  }

  void placeOrder() async {
    final products = await _productsFuture;
    double total = 0;
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.receipt_long, size: 24),
              Text("訂單明細", style: theme.textTheme.titleLarge),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children:
                  selectedProducts.map((index) {
                    final product = products[index];
                    total +=
                        double.parse(product['price']) * product['quantity'];
                    return ListTile(
                      title: Text(product['name']),
                      subtitle: Text('數量: ${product['quantity']}'),
                      trailing: Text(
                        '\$${(double.parse(product['price']) * product['quantity']).toStringAsFixed(2)}',
                      ),
                    );
                  }).toList(),
            ),
          ),
          actions: [
            Text("總共\$${total.toStringAsFixed(2)}"),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    pushOrder();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                  child: const Text("送出"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("關閉"),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void removeOrder() async {
    final products = await _productsFuture;
    setState(() {
      for (var product in products) {
        product['quantity'] = 1;
      }
      selectedProducts.clear();
    });
    if (!mounted) return;
    MessageService.showMessage(context, "刷新當前訂單完畢");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          Expanded(
            child: HomeContent(
              productsFuture: _productsFuture,
              selectedProducts: selectedProducts,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: DownOperations(
              onPlaceOrder: placeOrder,
              onRemoveOrder: removeOrder,
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      bottomNavigationBar: const CustomBottomBar(currentIndex: 1),
    );
  }
}

class DownOperations extends StatelessWidget {
  final VoidCallback onPlaceOrder;
  final VoidCallback onRemoveOrder;

  const DownOperations({
    super.key,
    required this.onPlaceOrder,
    required this.onRemoveOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: onPlaceOrder,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          child: Text("提交訂單", style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        ),
        ElevatedButton(
          onPressed: onRemoveOrder,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: Text("清除訂單", style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
        ),
      ],
    );
  }
}
