import 'package:calendar_app/admin/calendar_page.dart';
import 'package:calendar_app/project_management/project_management_calendar_page.dart';
import 'package:calendar_app/project_management/project_management_chat_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class ProjectManagerHomePage extends StatefulWidget {
  const ProjectManagerHomePage({super.key});

  @override
  State<ProjectManagerHomePage> createState() => _ProjectManagerHomePage();
}

class _ProjectManagerHomePage extends State<ProjectManagerHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // _pages içinde HomePage'in kendisini eklemeyin, bu bir sonsuz döngü yaratır.
    List<Widget> _pages = [
      ProjectManagementCalendarPage(),  // Takvim sayfası
      ProjectManagementChatPage(),      // Sohbet sayfası
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex, // Güncel indeks burada kullanılıyor
        buttonBackgroundColor: Colors.white.withOpacity(0.1),
        color: const Color.fromARGB(255, 220, 220, 220),
        animationDuration: const Duration(milliseconds: 300),
        items: const <Widget>[
          Icon(
            Icons.calendar_today,
            size: 30,
            color: Color.fromARGB(255, 120, 124, 236),
          ),
          Icon(
            Icons.chat,
            size: 30,
            color: Color.fromARGB(255, 120, 124, 236),
          ), // Sohbet ikonu
        ],
        onTap: _onItemTapped,
        backgroundColor:
        const Color.fromARGB(255, 255, 255, 255), // Arka plan rengi
      ),
    );
  }
}
