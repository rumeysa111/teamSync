/*
import 'package:calendar_app/api/firebase_api.dart';
import 'package:calendar_app/management_team/management_team_home_page.dart';
import 'package:calendar_app/project_management/project_management_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/home_page.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


final navigatorKey= GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  //kontrol et ve dogru ekranı seç
  final prefs = await SharedPreferences.getInstance();
  final deviceId = prefs.getString('token');
  Widget startWidget;
  if (deviceId != null) {
    // Daha önce giriş yapılmış
    startWidget = await _getStartedWidgetForUser();
  } else {
    // İlk giriş veya cihaz kimliği mevcut değil
    startWidget = LoginScreen();
  }

  runApp( MyApp(startWidget : startWidget));
}
Future<Widget> _getStartedWidgetForUser() async{
  final prefs = await SharedPreferences.getInstance();
  final team = prefs.getString('team'); // Kullanıcı rolünü SharedPreferences'dan al
  print('User team: $team');

  switch(team){
  case 'admin':
    return HomePage();
  case 'Proje Arastirma ve Analiz Takimi':
    return ProjectManagerHomePage();
    case 'Yönetim Kurulu':
      return ManagementTeamHomePage();
  default:
    return HomePage();
}
}

class MyApp extends StatelessWidget {
  final Widget startWidget;

  const MyApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: startWidget,
      navigatorKey: navigatorKey,
    );
  }
}


*/

import 'package:calendar_app/api/firebase_api.dart';
import 'package:calendar_app/management_team/management_team_home_page.dart';
import 'package:calendar_app/project_management/project_management_home_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/home_page.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


final navigatorKey= GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseApi().initNotifications();
  //kontrol et ve dogru ekranı seç
  final prefs = await SharedPreferences.getInstance();
  final deviceId = prefs.getString('token');
  Widget startWidget;
  if (deviceId != null) {
    // Daha önce giriş yapılmış
    startWidget = await _getStartedWidgetForUser();
  } else {
    // İlk giriş veya cihaz kimliği mevcut değil
    startWidget = LoginScreen();
  }

  runApp( MyApp(startWidget : startWidget));
}
Future<Widget> _getStartedWidgetForUser() async{
  final prefs = await SharedPreferences.getInstance();
  final team = prefs.getString('team'); // Kullanıcı rolünü SharedPreferences'dan al
  print('User team: $team');

  switch(team){
    case 'admin':
      return HomePage();
    case 'Proje Arastirma ve Analiz Takimi':
      return ProjectManagerHomePage();
    case 'Yönetim Kurulu':
      return ManagementTeamHomePage();
    default:
      return HomePage();
  }
}

class MyApp extends StatelessWidget {
  final Widget startWidget;

  const MyApp({super.key, required this.startWidget});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: startWidget,
      navigatorKey: navigatorKey,
    );
  }
}










