import 'package:flutter/material.dart';
import '../core/push_notification_service.dart';
import '../core/in_app_notification_service.dart';
import 'overview/overview_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize push notification listener & token registration
    PushNotificationService().initialize();
    // Initialize real-time in-app notification listener
    InAppNotificationService().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return const OverviewScreen();
  }
}
