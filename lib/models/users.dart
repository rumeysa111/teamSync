import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String password;
  final String role; // Örneğin, "member", "admin" gibi
  final String teamId; // Kullanıcının ait olduğu takım ID'si
  final String deviceToken; // Cihaz token'ı

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.teamId,
    required this.deviceToken,
  });

  // Firestore'dan bir DocumentSnapshot alarak User modeline dönüştüren fabrika fonksiyonu
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      username: data['username'] ?? '',
      password: data['password'] ?? '',
      role: data['role'] ?? '',
      teamId: data['teamId'] ?? '',
      deviceToken: data['deviceToken'] ?? '', // deviceToken alanı eklendi
    );
  }

  // User modelini bir Map'e dönüştürmek için kullanılan fonksiyon
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'teamId': teamId,
      'deviceToken': deviceToken, // deviceToken alanı eklendi
    };
  }
}
