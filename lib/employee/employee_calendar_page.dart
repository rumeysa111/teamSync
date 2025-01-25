import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar_app/api/firebase_api.dart';

import '../profile_page.dart';

class EmployeeCalendarPage extends StatefulWidget {
  @override
  _EmployeeCalendarPageState createState() => _EmployeeCalendarPageState();
}

class _EmployeeCalendarPageState extends State<EmployeeCalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<QueryDocumentSnapshot> _events = [];
  List<QueryDocumentSnapshot> _upcomingEvents = [];
  TimeOfDay _selectedTime = TimeOfDay.now();
  Map<DateTime, List<QueryDocumentSnapshot>> _eventsMap = {};
  bool _isDropdownOpen = false;
  List<String> teams = [];
  List<String> _selectedTeams = [];
  final FirebaseApi _firebaseApi = FirebaseApi(); // FirebaseApi instance'ını oluşturun




  @override
  void initState() {
    super.initState();
    _fetchEvents();

  }

  void _fetchEvents() async {
    try {
      final now = DateTime.now().toUtc(); // Tarihi UTC formatına çevir
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? teamId = prefs.getString('teamId');
      print('team id ${teamId}');

      if (teamId != null) {
        final eventsSnapshot = await FirebaseFirestore.instance
            .collection('events')
            .where('teamsIds', arrayContains: teamId)
            .where('date', isGreaterThanOrEqualTo: now) // Gelecekteki etkinlikler
            .orderBy('date')
            .get();

        print('gelen etkinlik sayısı : ${eventsSnapshot.docs.length}');

        // Ekranı güncelle
        if (mounted) {
          setState(() {
            _events = eventsSnapshot.docs;

            _upcomingEvents = _events.where((event) {
              DateTime eventDate = (event['date'] as Timestamp).toDate();
              return eventDate.isAfter(DateTime.now());
            }).toList();

            print('Etkinlikler: ${_events.length}');
          });
        }
      } else {
        print('teamId bulunamadı');
      }
    } catch (e) {
      print('Firestore sorgusu sırasında bir hata oluştu: $e');
    }
  }


  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

  }






  Future<List<String>> _fetchTeamsByAdminId(String? adminId) async {
    if (adminId == null) return [];

    final teamsSnapshot = await FirebaseFirestore.instance
        .collection('ekipler')
        .where('adminId', isEqualTo: adminId)
        .get();

    return teamsSnapshot.docs.map((doc) => doc['ad'] as String).toList();
  }




  Future<List<String>> _fetchDeviceTokensForTeams(List<String> teams) async {
    List<String> deviceTokens = [];

    try {
      for (String team in teams) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('team', whereIn: teams)
            .get();

        for (var doc in usersSnapshot.docs) {
          if (doc['token'] != null) {
            deviceTokens.add(doc['token']);
          }
        }
      }
    } catch (e) {
      print('Cihaz tokenları alınırken bir hata oluştu: $e');
      // Kullanıcıya hata hakkında bilgi vermek için bir mekanizma ekleyebilirsiniz
    }

    return deviceTokens;
  }


  @override

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(75.0),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 120, 124, 236),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(35),
            ),
          ),
          child: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            centerTitle: true,
            title: Text(
              'Takvim',
              style: TextStyle(color: Colors.white, fontSize: 32),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.white,
                  size: 36,
                ),
                onPressed: () {
                  // Ayarlar simgesine tıklandığında yapılacak işlemler
                },
              ),
            ],
            leading: IconButton(
              icon: Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: 36,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2034, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.month,
            eventLoader: (day) => _eventsMap[day] ?? [],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Yaklaşan Etkinlikler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = _upcomingEvents[index];
                final eventDate = (event['date'] as Timestamp).toDate();
                return ListTile(
                  title: Text(event['title']),
                  subtitle: Text('${eventDate.toLocal()} - ${event['description']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Buraya gerektiğinde eklenecek ekstra bileşenler
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}