import 'package:flutter/material.dart';

/// Custom popup dialog yang bisa digunakan di mana pun
class CustomPopup {
  /// Show success popup
  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _PopupDialog(
        icon: Icons.check_circle,
        iconColor: Colors.green,
        title: title,
        message: message,
        buttonText: buttonText ?? 'OK',
        buttonColor: Colors.green,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show error popup
  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _PopupDialog(
        icon: Icons.error_outline,
        iconColor: Colors.red,
        title: title,
        message: message,
        buttonText: buttonText ?? 'OK',
        buttonColor: Colors.red,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show warning popup
  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _PopupDialog(
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
        title: title,
        message: message,
        buttonText: buttonText ?? 'OK',
        buttonColor: Colors.orange,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show info popup
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _PopupDialog(
        icon: Icons.info_outline,
        iconColor: Colors.blue,
        title: title,
        message: message,
        buttonText: buttonText ?? 'OK',
        buttonColor: Colors.blue,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show confirmation popup dengan Yes/No buttons
  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _ConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText ?? 'Yes',
        cancelText: cancelText ?? 'No',
      ),
    );
  }

  /// Show rating success popup berdasarkan rating yang diberikan
  static Future<void> showRatingSuccess({
    required BuildContext context,
    required int rating,
    VoidCallback? onConfirm,
  }) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (rating) {
      case 5:
        title = 'Terima Kasih! ⭐⭐⭐⭐⭐';
        message = 'Senang sekali Anda puas dengan layanan kami! Rating 5 bintang sangat berarti untuk kami.';
        icon = Icons.sentiment_very_satisfied;
        color = Colors.green;
        break;
      case 4:
        title = 'Terima Kasih! ⭐⭐⭐⭐';
        message = 'Kami senang Anda menyukai layanan kami! Kami akan terus berusaha memberikan yang terbaik.';
        icon = Icons.sentiment_satisfied;
        color = Colors.lightGreen;
        break;
      case 3:
        title = 'Terima Kasih atas Rating Anda ⭐⭐⭐';
        message = 'Kami akan berusaha lebih baik lagi. Masukan Anda sangat berharga untuk kami.';
        icon = Icons.sentiment_neutral;
        color = Colors.orange;
        break;
      case 2:
        title = 'Mohon Maaf ⭐⭐';
        message = 'Kami mohon maaf jika ada yang kurang memuaskan. Kami akan segera memperbaiki layanan kami.';
        icon = Icons.sentiment_dissatisfied;
        color = Colors.deepOrange;
        break;
      case 1:
        title = 'Mohon Maaf atas Ketidaknyamanan ⭐';
        message = 'Kami sangat menyesal atas pengalaman yang kurang menyenangkan. Tim kami akan menindaklanjuti hal ini.';
        icon = Icons.sentiment_very_dissatisfied;
        color = Colors.red;
        break;
      default:
        title = 'Terima Kasih!';
        message = 'Rating Anda telah tersimpan.';
        icon = Icons.check_circle;
        color = Colors.blue;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PopupDialog(
        icon: icon,
        iconColor: color,
        title: title,
        message: message,
        buttonText: 'OK',
        buttonColor: color,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Show custom popup dengan widget kustom
  static Future<T?> showCustom<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}

/// Widget internal untuk popup dialog standar
class _PopupDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback? onConfirm;

  const _PopupDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.buttonColor,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget internal untuk confirmation dialog
class _ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  const _ConfirmationDialog({
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      cancelText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

