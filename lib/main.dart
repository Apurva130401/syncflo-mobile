import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'src/core/auth_provider.dart';
import 'src/core/constants.dart';
import 'src/core/theme.dart';
import 'src/navigation/root_navigation.dart';

void main() async {
  // Ensure Flutter engine is initialized before calling native modules
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: Constants.supabaseUrl,
    publishableKey: Constants.supabaseAnonKey,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const SyncfloApp(),
    ),
  );
}

class SyncfloApp extends StatelessWidget {
  const SyncfloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'Syncflo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: auth.themeMode,
          builder: (context, child) {
            final brightness = auth.themeMode == ThemeMode.system
                ? MediaQuery.of(context).platformBrightness
                : (auth.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
            AppColors.updateTheme(brightness);
            return child!;
          },
          home: const RootNavigation(),
        );
      },
    );
  }
}
