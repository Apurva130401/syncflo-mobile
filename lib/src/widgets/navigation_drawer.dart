import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/theme.dart';
import '../screens/home_screen.dart';
import '../navigation/root_navigation.dart';
import '../screens/inbox/conversation_list.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/ctwa/ctwa_screen.dart';
import '../screens/agents/agents_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/notifications/notifications_center_screen.dart';
import '../screens/billing/billing_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/contacts/contacts_screen.dart';

class NavigationDrawerWidget extends StatelessWidget {
  final String currentRoute;

  const NavigationDrawerWidget({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Drawer(
      backgroundColor: AppColors.background,
      child: Column(
        children: [
          // Drawer Header with Company Name & Theme Toggle
          Container(
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Company Name display
                Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.building_2, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          auth.profile?.companyName ?? 'My Workspace',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Theme Toggle Buttons Row (Sun, Moon, PC)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemeToggleIcon(
                      icon: LucideIcons.sun,
                      isActive: auth.themeMode == ThemeMode.light,
                      tooltip: 'Light Theme',
                      onTap: () => auth.setThemeMode(ThemeMode.light),
                    ),
                    _buildThemeToggleIcon(
                      icon: LucideIcons.moon,
                      isActive: auth.themeMode == ThemeMode.dark,
                      tooltip: 'Dark Theme',
                      onTap: () => auth.setThemeMode(ThemeMode.dark),
                    ),
                    _buildThemeToggleIcon(
                      icon: LucideIcons.monitor,
                      isActive: auth.themeMode == ThemeMode.system,
                      tooltip: 'System Theme',
                      onTap: () => auth.setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.house,
                  label: 'Overview',
                  route: '/overview',
                  destination: const HomeScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.message_square,
                  label: 'Inbox / Chats',
                  route: '/inbox',
                  destination: const ConversationListScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.book_user,
                  label: 'Contacts',
                  route: '/contacts',
                  destination: const ContactsScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.activity,
                  label: 'Analytics',
                  route: '/analytics',
                  destination: const AnalyticsScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.megaphone,
                  label: 'Meta CTWA',
                  route: '/ctwa',
                  destination: const CtwaScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.bot,
                  label: 'AI Agents',
                  route: '/agents',
                  destination: const AgentsScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.users,
                  label: 'Team Settings',
                  route: '/team',
                  destination: const TeamScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.bell,
                  label: 'Logs',
                  route: '/notifications',
                  destination: const NotificationsCenterScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.credit_card,
                  label: 'Billing & Usage',
                  route: '/billing',
                  destination: const BillingScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.settings,
                  label: 'Account Settings',
                  route: '/settings',
                  destination: const SettingsScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  icon: LucideIcons.info,
                  label: 'Support & Help',
                  route: '/support',
                  destination: const SupportScreen(),
                ),
              ],
            ),
          ),

          // Log Out Button at the bottom
          const Divider(),
          ListTile(
            leading: Icon(LucideIcons.log_out, color: AppColors.error),
            title: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              Navigator.pop(context); // Close Drawer
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RootNavigation()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThemeToggleIcon({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isActive ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required Widget destination,
  }) {
    final bool isSelected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.text,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.pop(context); // Close Drawer
          if (!isSelected) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => destination),
            );
          }
        },
      ),
    );
  }
}
