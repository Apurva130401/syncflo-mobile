import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../core/theme.dart';
import '../models/models.dart';

class InAppNotificationModalWidget extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onAction;
  final VoidCallback onDismiss;

  const InAppNotificationModalWidget({
    super.key,
    required this.notification,
    required this.onAction,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Determine details based on type (supports 'mobile_modal', 'mobile_success', etc.)
    final type = notification.type.toLowerCase();
    IconData iconData;
    Color iconColor;

    if (type.contains('success')) {
      iconData = LucideIcons.circle_check;
      iconColor = AppColors.success;
    } else if (type.contains('warning')) {
      iconData = LucideIcons.triangle_alert;
      iconColor = AppColors.warning;
    } else if (type.contains('error')) {
      iconData = LucideIcons.triangle_alert;
      iconColor = AppColors.error;
    } else {
      iconData = LucideIcons.info;
      iconColor = AppColors.primary;
    }

    final hasAction = notification.actionUrl != null && notification.actionUrl!.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border, width: 1.2),
      ),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.1),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notification.title,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        notification.message,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.4,
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: onDismiss,
          child: Text(
            'Close',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        if (hasAction)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textInverse,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: onAction,
            child: const Text(
              'View Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
