import 'package:calendar_app/assistant/assistan_home_page.dart';
import 'package:calendar_app/employee/employee_calendar_page.dart';
import 'package:calendar_app/employee/employee_home_page.dart';
import 'package:calendar_app/management_team/management_team_home_page.dart';
import 'package:calendar_app/project_management/project_management_home_page.dart';
import 'package:calendar_app/team_leader/team_leader_calendar.dart';
import 'package:calendar_app/team_leader/team_leader_home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin/home_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _errorMessage;Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      // Adminleri sorgula
      QuerySnapshot adminQuery = await _firestore
          .collection('admins')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      // Kullanıcıyı sorgula
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .where('password', isEqualTo: password)
          .get();

      final prefs = await SharedPreferences.getInstance();
      String? fCMToken = await _firebaseMessaging.getToken();

      if (adminQuery.docs.isNotEmpty) {
        // Admin giriş yaptı
        DocumentSnapshot adminDoc = adminQuery.docs.first;
        String adminId = adminDoc.id; // Admin belgesi kimliği

        // Token'ı admin belgesine kaydet
        await _firestore.collection('admins').doc(adminId).update({
          'token': fCMToken,
          'adminId': adminId,
        });

        await prefs.setString('adminId', adminId);

        // Yönlendirme
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()), // Admin sayfasına yönlendirme
        );
      } else if (userQuery.docs.isNotEmpty) {
        // Kullanıcı giriş yaptı
        DocumentSnapshot userDoc = userQuery.docs.first;
        String? teamName = userDoc.get('role');
        String? teamId = userDoc.get('teamId');
        String? adminId = userDoc.get('adminId');

        // Kullanıcı kimliğini kaydet
        String userId = userDoc.id; // Kullanıcı belgesi kimliği
        await prefs.setString('userId', userId); // Kullanıcı kimliğini kaydet

        if (adminId != null) {
          await prefs.setString('adminId', adminId);
        }

        if (fCMToken != null) {
          // Token'ı kullanıcının belgesine kaydet
          await _firestore.collection('users').doc(userDoc.id).update({
            'token': fCMToken,
            'admin': adminId,
            'userId': userId, // userId'yi kaydet
          });
        }
        await prefs.setString('teamId', teamId ?? '');

        // Yönlendirme
        Widget page;
        switch (teamName) {
          case 'admin':
            page = HomePage();
            break;
          case 'Proje Yonetici':
            page = ProjectManagerHomePage();
            break;
          case 'Yonetici':
            page = ManagementTeamHomePage();
            break;
          case 'Asistan':
            page = AssistanHomePage();
            break;
          case 'Ekip Lideri':
            page = TeamLeaderHomePage();
            break;
          case 'Çalışan':
            page = EmployeeHomePage();
            break;
          default:
            page = HomePage();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      } else {
        setState(() {
          _errorMessage = 'Geçersiz kullanıcı adı veya şifre';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
        print('rumeysa hata ${_errorMessage}');
      });
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan resmi
          Image.asset(
            'assets/images/loginbackground2.jpg',
            fit: BoxFit.cover,
          ),
          // İçerik
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.only(
                      top: 30.0, right: 20, left: 20, bottom: 20),
                  margin: const EdgeInsets.only(
                    top: 300,
                    left: 30.0,
                    right: 30.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7), // Saydam arka plan
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Color(0xFF40308D), width: 2), // Siyah çerçeve
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Kullanıcı Adı',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                          Icon(Icons.person, color: Color(0xFF40308D)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Color(0xFF40308D)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Color(0xFF40308D)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Color(0xFF40308D)),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon:
                          Icon(Icons.lock, color: Color(0xFF40308D)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Color(0xFF40308D)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Color(0xFF40308D)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Color(0xFF40308D)),
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF40308D), // Buton rengi
                          minimumSize:
                          Size(double.infinity, 55), // Buton boyutu
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8.0), // Dikdörtgen köşeler
                          ),
                        ),
                        child: Text(
                          'Giriş Yap',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                                color: const Color.fromARGB(255, 255, 0, 0)),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Yardım metninin tıklanma işlevi burada olacak
                    print('Yardım metni tıklandı');
                  },
                  child: Text(
                    'Yardım',
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}