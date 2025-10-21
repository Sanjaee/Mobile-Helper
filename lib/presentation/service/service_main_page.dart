import 'package:flutter/material.dart';
import 'service_home_page.dart';
import 'service_tutorial_page.dart';
import 'service_history_page.dart';
import 'service_chat_page.dart';

class ServiceMainPage extends StatefulWidget {
  const ServiceMainPage({super.key});

  @override
  State<ServiceMainPage> createState() => _ServiceMainPageState();
}

class _ServiceMainPageState extends State<ServiceMainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ServiceHomePage(),
    const ServiceTutorialPage(),
    const ServiceHistoryPage(),
    const ServiceChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Tutorial',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
        ],
      ),
    );
  }
}

