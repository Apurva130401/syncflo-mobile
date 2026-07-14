import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/home_screen.dart';
import '../widgets/takeover_manager.dart';

class RootNavigation extends StatelessWidget {
  const RootNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const SplashScreen();
        }

        if (auth.user != null) {
          return const TakeoverManager(child: HomeScreen());
        }

        return const LoginScreen();
      },
    );
  }
}
