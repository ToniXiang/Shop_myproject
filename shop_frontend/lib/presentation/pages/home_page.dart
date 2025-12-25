import 'package:shop_frontend/presentation/presentation.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      drawer: const CustomDrawer(),
      bottomNavigationBar: const CustomBottomBar(),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            height: 180,
            child: PageView(
              children: List.generate(
                3,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[200 * (index + 2)],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'Banner ${index + 1}',
                      style: const TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: '搜尋商品',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                5,
                (index) => Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(radius: 25, child: Text('圖${index + 1}')),
                      const SizedBox(height: 4),
                      Text(
                        '分類${index + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '限時秒殺',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                5,
                (index) => Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  color: Colors.orange[200 * (index + 2)],
                  child: Center(child: Text('特價商品${index + 1}')),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '為你推薦',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                5,
                (index) => Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  color: Colors.green[200 * (index + 2)],
                  child: Center(child: Text('推薦商品${index + 1}')),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '品牌專區',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(
                5,
                (index) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  color: Colors.purple[200 * (index + 2)],
                  child: Center(child: Text('品牌${index + 1}')),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '用戶分享',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('用戶分享內容 ${index + 1}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
