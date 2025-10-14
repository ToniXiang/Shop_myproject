import 'package:practice0419_frontend/data/data.dart';
import 'package:practice0419_frontend/presentation/presentation.dart';

class MessageService {
  static Future<void> removeToken() async {
    await AuthService.logout();
  }

  static void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.logout,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text('登出', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            content: const Text('確定要登出嗎?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () async {
                  MessageService.removeToken();
                  Navigator.of(context).pop();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('登出'),
              ),
            ],
          ),
    );
  }

  // Accept any object so callers can pass an Exception (`$e`) directly.
  // The message will be sanitized to remove prefixes like "Exception: ".
  static void showMessage(BuildContext context, Object? message) {
    final text = _sanitizeMessage(message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Removes common exception prefixes like "Exception: " or "SocketException: "
  static String _sanitizeMessage(Object? message) {
    if (message == null) return '';
    var s = message.toString();

    // Trim whitespace
    s = s.trim();

    // Remove patterns like "SomethingException: " at the start.
    final regex = RegExp(r'^[A-Za-z0-9_]+Exception:\s*');
    s = s.replaceFirst(regex, '');

    // Also remove a generic leading label before a colon if it looks like a prefix
    // (e.g. "Error: message"), but only when it's short (<= 20 chars) to avoid
    // removing meaningful content.
    final genericPrefix = RegExp(r'^[^:]{1,20}:\s*');
    if (genericPrefix.hasMatch(s)) {
      // Only strip if the prefix contains no spaces (likely a label) or is short
      final prefixMatch = genericPrefix.firstMatch(s);
      if (prefixMatch != null) {
        final prefix = prefixMatch.group(0) ?? '';
        if (!prefix.contains(' ') || prefix.length <= 20) {
          s = s.replaceFirst(genericPrefix, '');
        }
      }
    }

    return s;
  }
}
