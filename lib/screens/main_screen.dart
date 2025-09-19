import 'package:desaster/screens/heatmap.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'view_locations_screen.dart';
import 'add_location_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const List<Widget> _screens = <Widget>[
    HeatmapPage(),
    ViewLocationsScreen(),
    AddLocationScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppTheme.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      // Trigger animation
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedSwitcher(
        duration: AppTheme.animationDuration,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.1, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.cardShadow,
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _selectedIndex == 0 ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      Icons.thermostat,
                      color: _selectedIndex == 0
                          ? AppTheme.primaryColor
                          : AppTheme.textLight,
                    ),
                  );
                },
              ),
              label: 'Heat Map',
            ),
            BottomNavigationBarItem(
              icon: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _selectedIndex == 1 ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      Icons.map,
                      color: _selectedIndex == 1
                          ? AppTheme.primaryColor
                          : AppTheme.textLight,
                    ),
                  );
                },
              ),
              label: 'View Locations',
            ),
            BottomNavigationBarItem(
              icon: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _selectedIndex == 2 ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      Icons.add_location,
                      color: _selectedIndex == 2
                          ? AppTheme.primaryColor
                          : AppTheme.textLight,
                    ),
                  );
                },
              ),
              label: 'Add Location',
            ),

            BottomNavigationBarItem(
              icon: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _selectedIndex == 3 ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      Icons.settings,
                      color: _selectedIndex == 3
                          ? AppTheme.primaryColor
                          : AppTheme.textLight,
                    ),
                  );
                },
              ),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textLight,
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppTheme.textPrimary,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
