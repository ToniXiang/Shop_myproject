import 'package:shop_frontend/presentation/presentation.dart';
import 'package:shop_frontend/data/data.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        // 頂部小區域背景覆蓋
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).padding.top, // 狀態欄高度
            color: Colors.blueAccent,
          ),
        ),
        AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
          centerTitle: false,
          actions: [
            IconButton(
              tooltip: '搜尋',
              icon: Icon(Icons.search, color: theme.colorScheme.onSurface),
              onPressed: () {
                MessageService.showMessage(context, '搜尋功能尚未實作');
              },
            ),
            IconButton(
              tooltip: '購物車',
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: () {
                MessageService.showMessage(context, '購物車功能尚未實作');
              },
            ),
            const SizedBox(width: 8),
          ],
          toolbarHeight: 44, // 減少工具欄高度
          titleSpacing: 12, // 減少標題間距
        ),
      ],
    );
  }
}
