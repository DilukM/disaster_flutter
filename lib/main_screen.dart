import 'package:flutter/material.dart';
import 'view_locations_screen.dart';
import 'add_location_screen.dart';

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
    ViewLocationsScreen(),
    AddLocationScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 5),
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
                      Icons.map,
                      color: _selectedIndex == 0
                          ? Colors.blue.shade600
                          : Colors.grey.shade500,
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
                    scale: _selectedIndex == 1 ? _scaleAnimation.value : 1.0,
                    child: Icon(
                      Icons.add_location,
                      color: _selectedIndex == 1
                          ? Colors.blue.shade600
                          : Colors.grey.shade500,
                    ),
                  );
                },
              ),
              label: 'Add Location',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue.shade600,
          unselectedItemColor: Colors.grey.shade500,
          backgroundColor: Colors.white.withOpacity(0.95),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
          ),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
