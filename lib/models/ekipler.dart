import 'package:cloud_firestore/cloud_firestore.dart';

class Team {
  final String id;
  final String name;
  final String leaderId;
  final List<String> userIds; // Bu listede kullanıcı ID'leri olacak

  Team({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.userIds,
  });

  factory Team.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Team(
      id: doc.id,
      name: data['name'] ?? '',
      leaderId: data['leaderId'] ?? '',
      userIds: List<String>.from(data['userIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'leaderId': leaderId,
      'userIds': userIds,
    };
  }
}
