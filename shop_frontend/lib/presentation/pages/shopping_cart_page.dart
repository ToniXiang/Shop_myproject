import 'package:flutter/material.dart';

class HomeContent extends StatefulWidget {
  final Future<List<Map<String, dynamic>>> productsFuture;
  final Set<int> selectedProducts;
  const HomeContent({
    super.key,
    required this.productsFuture,
    required this.selectedProducts,
  });
  @override
  State<HomeContent> createState() => HomeContentState();
}

class HomeContentState extends State<HomeContent> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('沒有任何商品內容'));
        } else {
          final products = snapshot.data!;
          return SizedBox(
            height: 100,
            child: ListView.builder(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final isSelected = widget.selectedProducts.contains(index);
                return ListTile(
                  title: Text(product['name']),
                  subtitle: Text(
                    '\$${double.parse(product['price'].toString()).toStringAsFixed(2)}',
                  ),
                  leading: Icon(
                    isSelected ? Icons.check : Icons.shopping_cart,
                    color: isSelected ? Colors.green : null,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: () {
                          setState(() {
                            if (product['quantity'] > 1) {
                              product['quantity']--;
                            }
                          });
                        },
                      ),
                      Text(product['quantity'].toString()),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          setState(() {
                            product['quantity']++;
                          });
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        products[index]['quantity'] = 1;
                        widget.selectedProducts.remove(index);
                      } else {
                        widget.selectedProducts.add(index);
                      }
                    });
                  },
                );
              },
            ),
          );
        }
      },
    );
  }
}
