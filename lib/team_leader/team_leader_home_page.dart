import 'package:calendar_app/admin/calendar_page.dart';
import 'package:calendar_app/team_leader/team_leader_calendar.dart';
import 'package:calendar_app/team_leader/team_leader_chat.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

class TeamLeaderHomePage extends StatefulWidget {
  const TeamLeaderHomePage({super.key});

  @override
  State<TeamLeaderHomePage> createState() => _TeamLeaderHomePageState();
}

class _TeamLeaderHomePageState extends State<TeamLeaderHomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _pages = [
TeamLeaderCalendar(),
      TeamLeaderChat(),


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
          ), // Takvim ikonu

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
