import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final List<String> invitedTeams;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.invitedTeams,
  });

  // Firestore'dan alınan veriyi Event modeline çeviren fabrika metodu
  factory Event.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    return Event(
      id: snapshot.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      invitedTeams: List<String>.from(data['invitedTeams'] ?? []),
    );
  }

  // Event modelini Firestore'a kaydetmek için bir haritaya çeviren metot
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'date': Timestamp.fromDate(date),
      'invitedTeams': invitedTeams,
    };
  }
}
