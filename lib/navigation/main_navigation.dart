import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../orders/order_history_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int index = 0;

  final screens = const [
    HomeScreen(),
    OrderHistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(
              icon: Icon(Icons.receipt_long), label: "Orders"),
          NavigationDestination(
              icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
