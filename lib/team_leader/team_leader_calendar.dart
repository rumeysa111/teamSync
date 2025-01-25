import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:calendar_app/api/firebase_api.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../profile_page.dart';
class TeamLeaderCalendar extends StatefulWidget {
  @override
  _TeamLeaderCalendarState createState() => _TeamLeaderCalendarState();
}

class _TeamLeaderCalendarState extends State<TeamLeaderCalendar> {
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
  List<dynamic> _publicHolidays = []; // Resmi tatiller için liste


  void _fetchTeams() async {
    SharedPreferences prefs= await SharedPreferences.getInstance();
    String? teamId=prefs.getString('teamId');
    print('Team ID: $teamId');


    if(teamId !=null){
      final teamsSnapshot= await FirebaseFirestore.instance.collection('ekipler').where('teamId',isEqualTo: teamId).get();
      setState(() {
        teams = teamsSnapshot.docs.map((doc) => doc['ad'].toString()).toList();
      });
    }else{
      print('team Id bulunamadı');
    }

  }
  void _fetchPublicHolidays() async {
    try {
      final response = await http.get(Uri.parse('https://www.googleapis.com/calendar/v3/calendars/tr.turkish%23holiday@group.v.calendar.google.com/events?key=AIzaSyDeqhvkAhLeU8tLg86SsnfrElerT0RgbK4')); // Google Calendar API URL'si
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> holidays = data['items']; // 'items' kısmındaki verileri al
        setState(() {
          _publicHolidays = holidays.map((holiday) => holiday['start']['date']).toList(); // Tarihleri listeye ekle
        });
      } else {
        throw Exception('Failed to load holidays');
      }
    } catch (e) {
      print('Resmi tatiller alınırken bir hata oluştu: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchEvents();
    _fetchTeams();
    _fetchPublicHolidays(); // Resmi tatilleri çek

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

    _showEventDialog(selectedDay);
  }

  void _showEventDialog(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final _eventTitleController = TextEditingController();
        final _eventDescriptionController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Etkinlik Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Tarih: ${selectedDay.toLocal()}'),
                    TextField(
                      controller: _eventTitleController,
                      decoration: InputDecoration(labelText: 'Başlık'),
                    ),
                    TextField(
                      controller: _eventDescriptionController,
                      decoration: InputDecoration(labelText: 'Açıklama'),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDropdownOpen = !_isDropdownOpen;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Ekip Seçin:'),
                            Icon(
                              _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isDropdownOpen)
                      Container(
                        width: 300,
                        height: 150,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: teams.length,
                          itemBuilder: (context, index) {
                            final team = teams[index];

                            return CheckboxListTile(
                              title: Text(team),
                              value: _selectedTeams.contains(team),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedTeams.add(team);
                                  } else {
                                    _selectedTeams.remove(team);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    TextButton(
                      onPressed: () async {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _selectedTime = pickedTime;
                          });
                        }
                      },
                      child: Text('Saat Seç: ${_selectedTime.format(context)}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_eventTitleController.text.isNotEmpty &&
                        _eventDescriptionController.text.isNotEmpty &&
                        _selectedTeams.isNotEmpty) {
                      Navigator.of(context).pop();
                      await _addEvent(
                        selectedDay,
                        _eventTitleController.text,
                        _eventDescriptionController.text,
                        _selectedTeams,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Lütfen tüm alanları doldurun ve ekip seçin.'),
                      ));
                    }
                  },
                  child: Text('Ekle'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('İptal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEvent(String eventId) async {
    await FirebaseFirestore.instance.collection('events').doc(eventId).delete();
    _fetchEvents();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Etkinlik silindi.')),
    );
  }

  void _showEditDialog(QueryDocumentSnapshot event) async {
    final _eventTitleController = TextEditingController(text: event['title']);
    final _eventDescriptionController = TextEditingController(text: event['description']);
    List<String> selectedTeams = List<String>.from(event['invitedTeams']);

    //ekipleri team ıdye göre al
    SharedPreferences prefs= await SharedPreferences.getInstance();
    String? teamId=prefs.getString('teamId');
    List<String> teams= await _fetchTeamsByAdminId(teamId);


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Etkinlik Düzenle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _eventTitleController,
                      decoration: InputDecoration(labelText: 'Başlık'),
                    ),
                    TextField(
                      controller: _eventDescriptionController,
                      decoration: InputDecoration(labelText: 'Açıklama'),
                    ),

                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _updateEvent(
                      event.id,
                      _eventTitleController.text,
                      _eventDescriptionController.text,
                      selectedTeams,
                    );
                    Navigator.of(context).pop();
                  },
                  child: Text('Kaydet'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('İptal'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<List<String>> _fetchTeamsByAdminId(String? adminId) async {
    if (adminId == null) return [];

    final teamsSnapshot = await FirebaseFirestore.instance
        .collection('ekipler')
        .where('adminId', isEqualTo: adminId)
        .get();

    return teamsSnapshot.docs.map((doc) => doc['ad'] as String).toList();
  }

  void _updateEvent(String eventId, String title, String description, List<String> selectedTeams) async {
    await FirebaseFirestore.instance.collection('events').doc(eventId).update({
      'title': title,
      'description': description,
      'invitedTeams': selectedTeams,
    });
    _fetchEvents();
  }

  Future<void> _addEvent(DateTime date, String title, String description, List<String> selectedTeams) async {
    try {
      //shared prefencten adminIdyi al
      SharedPreferences prefs= await SharedPreferences.getInstance();
      String? adminId=prefs.getString('adminId');
      if(adminId==null){
        print('admin id bulunumadı');
        return;
      }
      // Seçilen ekibin teamId'sini al (örneğin: bir ekip seçildiğinde ekip adını teamId ile eşleştirebilirsiniz)

      List<String> teamsIds=[];
      for(String team in selectedTeams){
        //her ekinin teamıdsini almak için firestoreden ekip bilgilerini çek
        final teamSnapshot= await FirebaseFirestore.instance.collection('ekipler').where('ad',isEqualTo: team).get();

        if(teamSnapshot.docs.isNotEmpty){
          String teamId=teamSnapshot.docs.first.id;//teamId'yi al
          teamsIds.add(teamId);
        }
      }
      DateTime selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Etkinliği Firestore'a ekle
      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(selectedDateTime), // DateTime'i Timestamp'e çeviriyoruz
        'invitedTeams': selectedTeams,
        'teamsIds':teamsIds,//secilen ekiplerin teamsIdslerini ekle
       // 'adminId':adminId,//admin Idyi ekle
      });

      // Seçilen ekiplerin cihaz tokenlarını topla
      List<String> deviceTokens = await _fetchDeviceTokensForTeams(selectedTeams);

      // Bildirim gönder
      if (deviceTokens.isNotEmpty) {
        await _firebaseApi.sendNotification(deviceTokens, title, description);
      } else {
        print('Bildirim göndermek için hiç cihaz tokenı bulunamadı.');
      }

      // Etkinlikleri tekrar yükle
      _fetchEvents();
    } catch (e) {
      print('Etkinlik eklenirken bir hata oluştu: $e');
      // Kullanıcıya hata hakkında bilgi vermek için bir mekanizma ekleyebilirsiniz
    }
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
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final isHoliday = _publicHolidays.contains(day
                    .toIso8601String()
                    .split('T')
                    .first);
                return Container(
                  decoration: BoxDecoration(
                    shape: isHoliday ? BoxShape.circle : BoxShape.rectangle,
                    color: isHoliday ? Colors.purple : null,
                    // Resmi tatilse arka plan rengi
                    borderRadius: isHoliday ? null : BorderRadius.circular(8), // Eğer daire değilse köşe yumuşatma
                  ),
                  child: Center(
                    child: Text(
                      day.day.toString(),
                      style: TextStyle(
                        color: isHoliday ? Colors.white : Colors
                            .black, // Yazı rengi
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Column(
            children: [
              Padding(padding: const EdgeInsets.all(8.0),
                child: Text('Yaklaşan Etkinlikler',style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              )
            ],
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
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditDialog(event),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          // Silme işlemi için onay almak için bir dialog gösterebilirsiniz
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Etkinliği Sil'),
                                content: Text('Bu etkinliği silmek istediğinizden emin misiniz?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(); // Dialog'u kapat
                                    },
                                    child: Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      _deleteEvent(event.id); // Etkinliği sil
                                      Navigator.of(context).pop(); // Dialog'u kapat
                                    },
                                    child: Text('Sil'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
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