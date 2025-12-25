import 'package:shop_frontend/presentation/presentation.dart';

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  const CustomBottomBar({super.key, this.currentIndex = 0});

  @override
  State<CustomBottomBar> createState() => _BottomBar();
}

class _BottomBar extends State<CustomBottomBar> {
  late int selectedPageIndex;
  @override
  void initState() {
    super.initState();
    selectedPageIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedPageIndex,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '首頁',),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: '分類'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: '訂單紀錄'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '個人中心'),
      ],
      onTap: (index) {
        setState(() {
          selectedPageIndex = index;
        });
        switch (index) {
          case 0:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
            break;
          case 1:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ClassificationPage()),
            );
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OrderHistoryPage()),
            );
            break;
          case 3:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AccountPage()),
            );
        }
      },
    );
  }
}
