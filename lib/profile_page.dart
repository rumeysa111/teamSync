import 'package:calendar_app/login_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String fullName = '';
  String userId = ''; // Kullanıcı ID'si
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUserId(); // Kullanıcı ID'sini yükle
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedAdminId = prefs.getString('adminId'); // Admin ID'yi kontrol et
    String? savedUserId = prefs.getString('userId'); // User ID'yi kontrol et

    if (savedAdminId != null) {
      setState(() {
        userId = savedAdminId; // Admin ID'yi kullan
        isAdmin = true; // Kullanıcı admin
      });
      _fetchAdminData(savedAdminId); // Admin verisini çek
    } else if (savedUserId != null) {
      setState(() {
        userId = savedUserId; // Kullanıcı ID'sini kullan
        isAdmin = false; // Kullanıcı normal kullanıcı
      });
      _fetchUserData(savedUserId); // Kullanıcı verisini çek
    }
  }

  Future<void> _fetchAdminData(String id) async {
    DocumentSnapshot adminDoc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(id)
        .get();

    if (adminDoc.exists) {
      setState(() {
        fullName = adminDoc['İsim']; // Adminin ismini al
      });
    }
  }

  Future<void> _fetchUserData(String id) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .get();

    if (userDoc.exists) {
      setState(() {
        fullName = userDoc['isim']; // Kullanıcının ismini al
      });
    }
  }

  void _changePassword() async {
    // Şifre değiştirme için bir dialog açın
    String? newPassword;
    await showDialog(
      context: context,
      builder: (context) {
        TextEditingController passwordController = TextEditingController();
        return AlertDialog(
          title: Text('Şifre Değiştir'),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: 'Yeni Şifre'),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                newPassword = passwordController.text;
                Navigator.of(context).pop();
              },
              child: Text('Onayla'),
            ),
          ],
        );
      },
    );

    if (newPassword != null && newPassword!.isNotEmpty) {
      if (isAdmin) {
        // Admin koleksiyonunda şifre güncelle
        await FirebaseFirestore.instance.collection('admins').doc(userId).update({
          'password': newPassword, // Şifre alanını güncelle
        });
      } else {
        // User koleksiyonunda şifre güncelle
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'password': newPassword, // Şifre alanını güncelle
        });
      }

      // Şifre değiştirildiğinde bir mesaj göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifre başarıyla değiştirildi!')),
      );
    }
  }


  void _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // User ID'sini kaldır
    await prefs.remove('adminId'); // Admin ID'sini kaldır

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()), // Giriş sayfası
          (route) => false, // Tüm sayfaları kaldır
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profil Sayfası'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/avatar.png'),
              ),
              SizedBox(height: 20),
              Text(
                fullName,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), // İsim stil
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _changePassword,
                child: Text('Şifre Değiştir'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Buton boyutu
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                child: Text('Çıkış Yap'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15), // Buton boyutu
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
