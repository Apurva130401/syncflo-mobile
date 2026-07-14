import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../billing/billing_screen.dart';
import 'notification_preferences_screen.dart';
import 'profile_edit_screen.dart';
import '../../navigation/root_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Profile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _supabaseService.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // Use profile data from DB, fall back to auth metadata
    final String firstName = _profile?.firstName ?? auth.user?.firstName ?? '';
    final String lastName = _profile?.lastName ?? auth.user?.lastName ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';
    final String email = _profile?.email ?? auth.user?.email ?? '';
    final String role = _profile?.role ?? auth.user?.role ?? 'agent';
    final String? phone = _profile?.phone;
    final String? companyName = _profile?.companyName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/settings'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadProfile,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              initials,
                              style: TextStyle(
                                color: AppColors.textInverse,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName.isNotEmpty ? fullName : 'SyncFlo Agent',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          if (phone != null && phone.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (companyName != null && companyName.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(LucideIcons.building_2, size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  companyName,
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // List Options
                    Container(
                      color: AppColors.surface,
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(LucideIcons.user, color: AppColors.primary, size: 20),
                            title: Text('Edit Profile', style: TextStyle(color: AppColors.text, fontSize: 15)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textMuted, size: 16),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                              );
                              // Refresh profile when returning from edit screen
                              _loadProfile();
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.bell, color: AppColors.primary, size: 20),
                            title: Text('Notifications', style: TextStyle(color: AppColors.text, fontSize: 15)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textMuted, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(LucideIcons.credit_card, color: AppColors.primary, size: 20),
                            title: Text('Billing & Subscription', style: TextStyle(color: AppColors.text, fontSize: 15)),
                            trailing: Icon(LucideIcons.chevron_right, color: AppColors.textMuted, size: 16),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BillingScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Logout Button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: auth.isLoading
                              ? null
                              : () async {
                                  await auth.logout();
                                  if (context.mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const RootNavigation()),
                                      (route) => false,
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: AppColors.text,
                          ),
                          child: auth.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.text),
                                  ),
                                )
                              : const Text('Sign Out'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}
