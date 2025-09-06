import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/settings_service.dart';
import 'auth/signin.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );

    _animationController.forward();
  }

  void _loadSettings() {
    setState(() {
      _notificationsEnabled = SettingsService.getNotificationsEnabled();
      _locationEnabled = SettingsService.getLocationEnabled();
      _themeMode = SettingsService.getThemeMode();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final result = await SettingsService.logout();

        if (mounted) {
          Navigator.of(context).pop(); // Remove loading dialog

          if (result.isSuccess) {
            // Navigate to signin page and clear navigation stack
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const SignInPage()),
                (route) => false,
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.errorMessage ?? 'Logout failed'),
                  backgroundColor: AppTheme.errorColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Remove loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An error occurred during logout'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfileSection() {
    final userEmail = SettingsService.getUserEmail();
    final userName = SettingsService.getUserDisplayName();

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingLg),
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: AppTheme.spacingLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail ?? 'No email',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppTheme.spacingSm,
              bottom: AppTheme.spacingSm,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required String title,
    String? subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing:
          trailing ??
          const Icon(Icons.chevron_right, color: AppTheme.textLight),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(position: _slideAnimation, child: child),
          );
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AppTheme.spacingLg),

              // Profile Section
              _buildProfileSection(),

              const SizedBox(height: AppTheme.spacingXl),

              // Preferences Section
              _buildSettingsSection('Preferences', [
                _buildSettingsItem(
                  title: 'Notifications',
                  subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                  icon: Icons.notifications_outlined,
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                        SettingsService.setNotificationsEnabled(value);
                      });
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.5),
                    trackOutlineColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      return Colors.transparent;
                    }),
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  title: 'Location Services',
                  subtitle: _locationEnabled ? 'Enabled' : 'Disabled',
                  icon: Icons.location_on_outlined,
                  trailing: Switch(
                    value: _locationEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationEnabled = value;
                        SettingsService.setLocationEnabled(value);
                      });
                    },
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppTheme.primaryColor,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: Colors.grey.withValues(alpha: 0.5),
                    trackOutlineColor: WidgetStateProperty.resolveWith((
                      states,
                    ) {
                      return Colors.transparent;
                    }),
                  ),
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  title: 'Theme',
                  subtitle: _themeMode.name.toUpperCase(),
                  icon: Icons.palette_outlined,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.white,
                        title: const Text('Choose Theme'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: ThemeMode.values.map((mode) {
                            return ListTile(
                              title: Text(mode.name.toUpperCase()),
                              leading: Radio<ThemeMode>(
                                value: mode,
                                groupValue: _themeMode,
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _themeMode = value;
                                      SettingsService.setThemeMode(value);
                                    });
                                    Navigator.of(context).pop();
                                  }
                                },
                              ),
                              onTap: () {
                                setState(() {
                                  _themeMode = mode;
                                  SettingsService.setThemeMode(mode);
                                });
                                Navigator.of(context).pop();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                ),
              ]),

              const SizedBox(height: AppTheme.spacingXl),

              // Account Section
              _buildSettingsSection('Account', [
                _buildSettingsItem(
                  title: 'App Version',
                  subtitle: SettingsService.getAppVersion(),
                  icon: Icons.info_outline,
                  trailing: const SizedBox.shrink(),
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  title: 'Privacy Policy',
                  icon: Icons.privacy_tip_outlined,
                  onTap: () {
                    // Navigate to privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy Policy - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  title: 'Terms of Service',
                  icon: Icons.description_outlined,
                  onTap: () {
                    // Navigate to terms of service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms of Service - Coming Soon'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _buildSettingsItem(
                  title: 'Logout',
                  icon: Icons.logout,
                  iconColor: AppTheme.errorColor,
                  trailing: const SizedBox.shrink(),
                  onTap: _logout,
                ),
              ]),

              const SizedBox(height: AppTheme.spacingXxl),
            ],
          ),
        ),
      ),
    );
  }
}
