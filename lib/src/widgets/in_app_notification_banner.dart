import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../core/theme.dart';
import '../models/models.dart';

class InAppNotificationBannerWidget extends StatefulWidget {
  final AppNotification notification;
  final VoidCallback onAction;
  final VoidCallback onDismissComplete;

  const InAppNotificationBannerWidget({
    super.key,
    required this.notification,
    required this.onAction,
    required this.onDismissComplete,
  });

  @override
  State<InAppNotificationBannerWidget> createState() => _InAppNotificationBannerWidgetState();
}

class _InAppNotificationBannerWidgetState extends State<InAppNotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _offsetAnimation;
  Timer? _autoDismissTimer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    ));

    // Slide down the banner
    _animationController.forward();

    // Set auto-dismiss timer for standard notifications (e.g., success, info)
    final type = widget.notification.type.toLowerCase();
    if (type != 'error' && type != 'warning') {
      _autoDismissTimer = Timer(const Duration(seconds: 4), () {
        _dismiss();
      });
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDismissing) return;
    setState(() {
      _isDismissing = true;
    });

    _autoDismissTimer?.cancel();
    _animationController.reverse().then((_) {
      widget.onDismissComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic styling based on notification type
    final type = widget.notification.type.toLowerCase();
    IconData iconData;
    Color iconColor;

    if (type == 'success') {
      iconData = LucideIcons.circle_check;
      iconColor = AppColors.success;
    } else if (type == 'warning') {
      iconData = LucideIcons.triangle_alert;
      iconColor = AppColors.warning;
    } else if (type == 'error') {
      iconData = LucideIcons.triangle_alert;
      iconColor = AppColors.error;
    } else {
      iconData = LucideIcons.info;
      iconColor = AppColors.primary;
    }

    final hasAction = widget.notification.actionUrl != null &&
        widget.notification.actionUrl!.isNotEmpty;

    return SlideTransition(
      position: _offsetAnimation,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Dismissible(
              key: Key(widget.notification.id),
              direction: DismissDirection.up,
              onDismissed: (_) {
                widget.onDismissComplete();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: iconColor.withValues(alpha: 0.1),
                              child: Icon(iconData, color: iconColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.notification.title,
                                    style: TextStyle(
                                      color: AppColors.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.notification.message,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _dismiss,
                              child: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        if (hasAction) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _dismiss,
                                child: Text(
                                  'Dismiss',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textInverse,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                onPressed: widget.onAction,
                                child: const Text(
                                  'View',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
