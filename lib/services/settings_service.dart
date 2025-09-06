import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'dart:developer' as developer;

/// Service class to handle app settings and user preferences
class SettingsService {
  // In-memory storage for settings (in a real app, use SharedPreferences)
  static ThemeMode _themeMode = ThemeMode.system;
  static bool _notificationsEnabled = true;
  static bool _locationEnabled = true;
  static String _languageCode = 'en';

  /// Get current theme mode
  static ThemeMode getThemeMode() {
    return _themeMode;
  }

  /// Set theme mode
  static bool setThemeMode(ThemeMode themeMode) {
    try {
      _themeMode = themeMode;
      developer.log('Theme mode set to: ${themeMode.name}');
      return true;
    } catch (e) {
      developer.log('Error setting theme mode: $e');
      return false;
    }
  }

  /// Get notifications enabled status
  static bool getNotificationsEnabled() {
    return _notificationsEnabled;
  }

  /// Set notifications enabled status
  static bool setNotificationsEnabled(bool enabled) {
    try {
      _notificationsEnabled = enabled;
      developer.log('Notifications enabled set to: $enabled');
      return true;
    } catch (e) {
      developer.log('Error setting notifications: $e');
      return false;
    }
  }

  /// Get location services enabled status
  static bool getLocationEnabled() {
    return _locationEnabled;
  }

  /// Set location services enabled status
  static bool setLocationEnabled(bool enabled) {
    try {
      _locationEnabled = enabled;
      developer.log('Location enabled set to: $enabled');
      return true;
    } catch (e) {
      developer.log('Error setting location: $e');
      return false;
    }
  }

  /// Get selected language code
  static String getLanguageCode() {
    return _languageCode;
  }

  /// Set language code
  static bool setLanguageCode(String languageCode) {
    try {
      _languageCode = languageCode;
      developer.log('Language code set to: $languageCode');
      return true;
    } catch (e) {
      developer.log('Error setting language code: $e');
      return false;
    }
  }

  /// Clear all settings (useful for reset or logout)
  static bool clearAllSettings() {
    try {
      _themeMode = ThemeMode.system;
      _notificationsEnabled = true;
      _locationEnabled = true;
      _languageCode = 'en';
      developer.log('All settings cleared');
      return true;
    } catch (e) {
      developer.log('Error clearing settings: $e');
      return false;
    }
  }

  /// Logout user and clear settings
  static Future<AuthResult> logout() async {
    try {
      // Sign out from Firebase
      final authResult = await AuthService.signOut();

      if (authResult.isSuccess) {
        // Clear user preferences but keep app settings
        // You can choose to keep some settings like theme, language
        // and only clear user-specific data

        developer.log('User logged out successfully');
        return AuthResult.success();
      } else {
        return authResult;
      }
    } catch (e) {
      developer.log('Error during logout: $e');
      return AuthResult.failure('An error occurred during logout');
    }
  }

  /// Get app version (this would typically come from package_info_plus)
  static String getAppVersion() {
    return "1.0.0"; // This should be dynamic in a real app
  }

  /// Get user email
  static String? getUserEmail() {
    final user = AuthService.currentUser;
    return user?.email;
  }

  /// Get user display name
  static String? getUserDisplayName() {
    final user = AuthService.currentUser;
    return user?.displayName ?? user?.email?.split('@').first;
  }
}

/// Settings item model for UI
class SettingsItem {
  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const SettingsItem({
    required this.title,
    this.subtitle,
    required this.icon,
    this.onTap,
    this.trailing,
    this.iconColor,
  });
}

/// Settings section model for UI
class SettingsSection {
  final String title;
  final List<SettingsItem> items;

  const SettingsSection({required this.title, required this.items});
}
